let mapWidth = 0;
function resizeAtlasMap() {
  const el = ['priority_map','landcover_map'].map(id=>document.getElementById(id)).find(el=>el && el.offsetWidth);
  if (!el || !el.offsetWidth || !window.HTMLWidgets) return;
  const widget = HTMLWidgets.find('#'+el.id);
  if (!widget || !widget.getMap) return;
  const map = widget.getMap();
  map.invalidateSize({pan:false});
  if (mapWidth !== el.offsetWidth) {
    map.fitBounds([[-39.2,140.9],[-33.95,150.05]],{animate:false,padding:[12,12]});
    mapWidth = el.offsetWidth;
  }
}
window.addEventListener('resize', () => requestAnimationFrame(resizeAtlasMap));
document.addEventListener('click', function(e) {
  const nav = e.target.closest('[data-page]');
  if (nav) {
    document.querySelectorAll('.atlas-page').forEach(el => {el.hidden = el.id !== 'page-' + nav.dataset.page;});
    document.querySelectorAll('[data-page]').forEach(el => {
      el.classList.toggle('active', el === nav);
      if (el === nav) el.setAttribute('aria-current','page'); else el.removeAttribute('aria-current');
    });
    window.dispatchEvent(new Event('resize'));
    if (window.Shiny) Shiny.setInputValue('page',nav.dataset.page,{priority:'event'});
  }
  const cell = e.target.closest('[data-action][data-area]');
  if(cell && window.Shiny) Shiny.setInputValue('cell',{area:cell.dataset.area,action:cell.dataset.action},{priority:'event'});
  const remove = e.target.closest('[data-remove]');
  if(remove && window.Shiny) Shiny.setInputValue('remove_pin',remove.dataset.remove,{priority:'event'});
  const focus = e.target.closest('[data-focus]');
  if(focus && window.Shiny) Shiny.setInputValue('focus_area',focus.dataset.focus,{priority:'event'});
});
