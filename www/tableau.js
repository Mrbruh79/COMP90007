/* Tableau Public Embedding API v3. Local evidence never depends on this module. */
(function (root) {
  const PARAMETERS = {focus:'Main area',compare1:'Additional area 1 (optional)',compare2:'Additional area 2 (optional)',compare3:'Additional area 3 (optional)',class:'Cover type',start:'Earlier period',end:'Later period'};
  class LandscapeBridge {
    constructor(client, report) {
      this.client = client; this.report = report; this.desired = null;
      this.applied = {}; this.busy = false; this.ready = false; this.closed = false;
    }
    async connect(release) {
      const parameters = await this.client.getParametersAsync();
      const found = Object.fromEntries(parameters.map(p => [p.name, p.currentValue.value]));
      if (found['Data release'] !== release) throw new Error('The dashboard uses a different data release.');
      for (const name of Object.values(PARAMETERS)) {
        if (!(name in found)) throw new Error('The dashboard selection controls are unavailable.');
        this.applied[name] = found[name];
      }
      if (this.closed) return;
      this.ready = true;
      await this.flush();
    }
    update(state) { this.desired = {...state}; return this.flush(); }
    async flush() {
      if (!this.ready || this.busy || this.closed || !this.desired) return;
      this.busy = true;
      try {
        while (!this.closed && this.desired) {
          const next = {...this.desired};
          for (const [key, name] of Object.entries(PARAMETERS)) {
            const value = next[key];
            if (this.closed) return;
            if (value !== undefined && this.applied[name] !== value) {
              await this.client.changeParameterValueAsync(name, value);
              this.applied[name] = value;
            }
          }
          if (Object.keys(PARAMETERS).every(key => next[key] === this.desired[key])) break;
        }
        if (!this.closed) this.report('ready', 'Tableau is connected. Area, class and epoch controls are synchronised.');
      } catch (error) {
        if (!this.closed) this.report('error', 'Your selection could not be applied. Retry, or explore the charts below.');
      } finally { this.busy = false; }
    }
    close() { this.closed = true; this.ready = false; }
  }
  if (typeof module !== 'undefined' && module.exports) { module.exports = {LandscapeBridge, PARAMETERS}; return; }
  let current = null, desired = {}, library = null;
  function status(host, state, message) {
    if (!host.isConnected) return;
    host.dataset.state = state;
    host.querySelector('#tableau-status').textContent = message;
    if (window.Shiny) Shiny.setInputValue('tableau_status',state,{priority:'event'});
    if (state === 'error' || state === 'timeout') document.getElementById('local-evidence').open = true;
  }
  async function mount(host) {
    if (current) { current.bridge?.close(); clearTimeout(current.timer); }
    const ticket = {host, bridge:null, timer:null}; current = ticket;
    host.querySelector('#tableau-mount').replaceChildren();
    status(host,'loading','Loading the dashboard…');
    ticket.timer = setTimeout(() => {
      if (current === ticket) status(host,'timeout','The dashboard is taking longer than expected. Charts and data are available below; you can retry.');
    },25000);
    try {
      // The library comes from the same host as the workbook to match its version.
      library = library || import('https://public.tableau.com/javascripts/api/tableau.embedding.3.latest.min.js');
      const {TableauViz,TableauEventType} = await library;
      if (current !== ticket || !host.isConnected) return;
      const viz = new TableauViz();
      viz.id = 'landscape-viz'; viz.src = host.dataset.viewUrl; viz.toolbar = 'bottom';
      viz.hideTabs = true; viz.width = '100%'; viz.height = '1710px';
      viz.addEventListener(TableauEventType.FirstInteractive,async () => {
        if (current !== ticket) return;
        clearTimeout(ticket.timer);
        try {
          ticket.bridge = new LandscapeBridge(viz.workbook,(state,message)=>status(host,state,message));
          ticket.bridge.desired = {...desired};
          await ticket.bridge.connect(host.dataset.release);
        } catch(error) { status(host,'error',error.message + ' Explore the charts below.'); }
      });
      viz.addEventListener('vizloaderror',() => {
        if (current !== ticket) return;
        clearTimeout(ticket.timer);status(host,'error','The dashboard could not load. Check your connection or explore the charts below.');
      });
      viz.addEventListener(TableauEventType.ParameterChanged,async event => {
        if (current !== ticket || !ticket.bridge?.ready || ticket.bridge.busy) return;
        try {
          const p = await event.detail.getParameterAsync();
          const key = Object.keys(PARAMETERS).find(key => PARAMETERS[key] === p.name);
          if (!key) return;
          const value = p.currentValue.value;
          ticket.bridge.applied[p.name] = value;
          desired[key] = value;
          ticket.bridge.desired = {...desired};
          if (window.Shiny) Shiny.setInputValue('tableau_parameter',{name:p.name,value},{priority:'event'});
        } catch(error) { status(host,'error','Tableau selection could not be read. Use the area, class and epoch controls above.'); }
      });
      host.querySelector('#tableau-mount').append(viz);
    } catch(error) {
      library = null; clearTimeout(ticket.timer);
      if (current === ticket) status(host,'error','The dashboard could not be reached. Charts and downloadable data remain available below.');
    }
  }
  function discover() {
    const host = document.getElementById('tableau-host');
    if (host && current?.host !== host) mount(host);
    if (!host && current) { current.bridge?.close();clearTimeout(current.timer);current = null; }
  }
  function register() {
    if (!window.Shiny || register.done) return;
    register.done = true;
    Shiny.addCustomMessageHandler('landscape-state',state => {
      desired = state; current?.bridge?.update(state);
    });
  }
  if (window.jQuery) window.jQuery(document).on('shiny:connected',register);
  document.addEventListener('shiny:connected',register);
  document.addEventListener('click',event => {
    if(event.target.closest('#tableau-retry')) { const host=document.getElementById('tableau-host'); if(host) mount(host); }
  });
  new MutationObserver(discover).observe(document.documentElement,{childList:true,subtree:true});
  register();discover();
})(typeof window === 'undefined' ? globalThis : window);
