/* Tableau Public Embedding API v3. Local evidence never depends on this module. */
(function (root) {
  class ProgressBridge {
    constructor(client, report) {
      this.client = client; this.report = report; this.desired = null;
      this.applied = {}; this.busy = false; this.ready = false; this.closed = false;
    }
    async connect(release) {
      const parameters = await this.client.getParametersAsync();
      const found = Object.fromEntries(parameters.map(p => [p.name, p.currentValue.value]));
      if (found['Data release'] !== release) throw new Error('The published workbook uses a different data release.');
      for (const name of ['Selected year', 'Selected action']) {
        if (!(name in found)) throw new Error('The published workbook is missing its selection controls.');
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
          for (const [name, value] of [['Selected year', next.year], ['Selected action', next.action]]) {
            if (this.closed) return;
            if (value && this.applied[name] !== value) {
              await this.client.changeParameterValueAsync(name, value);
              this.applied[name] = value;
            }
          }
          if (next.year === this.desired.year && next.action === this.desired.action) break;
        }
        if (!this.closed) this.report('ready', 'Tableau is connected. Year and action controls are synchronised.');
      } catch (error) {
        if (!this.closed) this.report('error', 'Tableau could not apply your selection. Retry, or use the local evidence.');
      } finally { this.busy = false; }
    }
    close() { this.closed = true; this.ready = false; }
  }
  if (typeof module !== 'undefined' && module.exports) { module.exports = {ProgressBridge}; return; }
  let current = null, desired = {year:'2021-22', action:'All actions'}, library = null;
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
    status(host,'loading','Loading the published Tableau dashboard…');
    ticket.timer = setTimeout(() => {
      if (current === ticket) status(host,'timeout','Tableau is taking longer than expected. Local charts and data are available below; you can retry.');
    },25000);
    try {
      // The library comes from the same host as the workbook to match its version.
      library = library || import('https://public.tableau.com/javascripts/api/tableau.embedding.3.latest.min.js');
      const {TableauViz,TableauEventType} = await library;
      if (current !== ticket || !host.isConnected) return;
      const viz = new TableauViz();
      viz.id = 'progress-viz'; viz.src = host.dataset.viewUrl; viz.toolbar = 'bottom';
      viz.hideTabs = true; viz.width = '100%'; viz.height = '1100px';
      viz.addEventListener(TableauEventType.FirstInteractive,async () => {
        if (current !== ticket) return;
        clearTimeout(ticket.timer);
        try {
          ticket.bridge = new ProgressBridge(viz.workbook,(state,message)=>status(host,state,message));
          ticket.bridge.desired = {...desired};
          await ticket.bridge.connect(host.dataset.release);
        } catch(error) { status(host,'error',error.message + ' Use the local evidence below.'); }
      });
      viz.addEventListener('vizloaderror',() => {
        if (current !== ticket) return;
        clearTimeout(ticket.timer);status(host,'error','The published Tableau dashboard could not load. Check your connection or use the local evidence below.');
      });
      viz.addEventListener(TableauEventType.ParameterChanged,async event => {
        if (current !== ticket || !ticket.bridge?.ready || ticket.bridge.busy) return;
        try {
          const p = await event.detail.getParameterAsync();
          if (!['Selected year','Selected action'].includes(p.name)) return;
          const value = p.currentValue.value;
          ticket.bridge.applied[p.name] = value;
          desired[p.name === 'Selected year' ? 'year' : 'action'] = value;
          ticket.bridge.desired = {...desired};
          if (window.Shiny) Shiny.setInputValue('tableau_parameter',{name:p.name,value},{priority:'event'});
        } catch(error) { status(host,'error','Tableau selection could not be read. Use the year and action controls above.'); }
      });
      host.querySelector('#tableau-mount').append(viz);
    } catch(error) {
      library = null; clearTimeout(ticket.timer);
      if (current === ticket) status(host,'error','Tableau could not be reached. Local charts and downloadable data remain available below.');
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
    Shiny.addCustomMessageHandler('progress-state',state => {
      desired = state; current?.bridge?.update(state);
    });
  }
  document.addEventListener('shiny:connected',register);
  document.addEventListener('click',event => {
    if(event.target.closest('#tableau-retry')) { const host=document.getElementById('tableau-host'); if(host) mount(host); }
  });
  new MutationObserver(discover).observe(document.documentElement,{childList:true,subtree:true});
  register();discover();
})(typeof window === 'undefined' ? globalThis : window);
