(function (root) {
  const PARAMETERS = {focus:'Main area',compare1:'Additional area 1 (optional)',compare2:'Additional area 2 (optional)',compare3:'Additional area 3 (optional)',class:'Cover type',start:'Earlier period',end:'Later period'};
  async function clearSavedAreaFilters(workbook) {
    const sheet = workbook.activeSheet?.worksheets?.find(sheet => sheet.name === 'T04_NetChange');
    if (!sheet) return;
    // Published copies can retain a manual area selection from Desktop.
    // Area membership comes from the shared parameters, so remove that extra restriction.
    // The class, comparison and endpoint calculation filters remain in place.
    for (const filter of await sheet.getFiltersAsync()) {
      const isArea = /:(AreaSeries|unit_label|microID):/.test(filter.fieldId || '');
      // Clear even when the client reports all values selected; that flag can
      // briefly describe the previous state after a manual filter interaction.
      if (isArea && filter.filterType === 'categorical')
        await sheet.clearFilterAsync(filter.fieldName);
    }
  }
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
      await clearSavedAreaFilters(this.client);
      if (this.closed) return;
      this.ready = true;
      await this.flush();
    }
    update(state) { this.desired = {...state}; return this.flush(); }
    async flush() {
      if (!this.ready || this.busy || this.closed || !this.desired) return;
      this.busy = true;
      try {
        if (Object.entries(PARAMETERS).some(([key,name]) => this.desired[key] !== undefined && this.applied[name] !== this.desired[key])) {
          this.report('syncing', 'Updating chart selection...');
          await clearSavedAreaFilters(this.client);
        }
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
        if (!this.closed) this.report('ready', 'Selection linked to map');
      } catch (error) {
        if (!this.closed) this.report('error', 'Selection could not be applied. Retry or use the local history chart below.');
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
    if (state === 'error' || state === 'timeout') {
      const evidence = document.getElementById('local-evidence');
      if (evidence) evidence.open = true;
    }
  }
  async function mount(host) {
    if (current) { current.bridge?.close(); clearTimeout(current.timer); current.observer?.disconnect(); }
    const ticket = {host, bridge:null, timer:null, observer:null}; current = ticket;
    host.querySelector('#tableau-mount').replaceChildren();
    status(host,'loading','Loading charts...');
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
      let nativeWidth = 1180, nativeHeight = 1290;
      viz.hideTabs = true; viz.width = nativeWidth + 'px'; viz.height = nativeHeight + 'px';
      // The published workbook uses floating objects at fixed desktop sizes.
      // Scale the complete view together, including its controls and toolbar.
      // Preserve a readable minimum width and allow local horizontal scrolling.
      const viewport = host.querySelector('.tableau-viewport');
      const mountPoint = host.querySelector('#tableau-mount');
      const fit = () => {
        if (viewport.clientWidth <= 0) return;
        const width = Math.max(Math.min(1170,nativeWidth),Math.min(nativeWidth,viewport.clientWidth));
        const scale = width / nativeWidth;
        mountPoint.style.width = width + 'px';
        mountPoint.style.height = Math.ceil(nativeHeight * scale) + 'px';
        viz.style.width = nativeWidth + 'px';
        viz.style.height = nativeHeight + 'px';
        viz.style.transform = 'scale(' + scale + ')';
      };
      ticket.observer = new ResizeObserver(fit);
      ticket.observer.observe(viewport);
      viz.addEventListener(TableauEventType.FirstInteractive,async () => {
        if (current !== ticket) return;
        clearTimeout(ticket.timer);
        try {
          const size = viz.workbook.activeSheet.size;
          if (size?.minSize?.width > 0 && size?.minSize?.height > 0) {
            nativeWidth = size.minSize.width; nativeHeight = size.minSize.height + 50;
            viz.width = nativeWidth + 'px'; viz.height = nativeHeight + 'px';
            fit();
          }
          ticket.bridge = new LandscapeBridge(viz.workbook,(state,message) => {
            if (current === ticket) status(host,state,message);
          });
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
      fit();
    } catch(error) {
      library = null; clearTimeout(ticket.timer);
      if (current === ticket) status(host,'error','The dashboard could not be reached. Charts and downloadable data remain available below.');
    }
  }
  function discover() {
    const host = document.getElementById('tableau-host');
    // Wait until the landscape page is visible before measuring the embed.
    if (host && host.getBoundingClientRect().width > 0 && current?.host !== host) mount(host);
    if (!host && current) { current.bridge?.close();clearTimeout(current.timer);current.observer?.disconnect();current = null; }
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
  new MutationObserver(discover).observe(document.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['hidden']});
  register();discover();
})(typeof window === 'undefined' ? globalThis : window);
