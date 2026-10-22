// Optional browser test. Install Playwright separately; see docs/VALIDATION.md.
const {spawn}=require('child_process');
const fs=require('fs');
const assert=require('assert');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const port=Number(process.env.QA_PORT || 7383);
const url=`http://127.0.0.1:${port}`;
(async()=>{
  const server=spawn(process.env.RSCRIPT || 'Rscript',['-e',`shiny::runApp(".",host="127.0.0.1",port=${port},launch.browser=FALSE)`],{cwd:process.cwd(),env:process.env,windowsHide:true});
  let log='';server.stdout.on('data',d=>{log+=d;});server.stderr.on('data',d=>{log+=d;});
  let browser; const checks=[];
  const check=(value,label)=>{assert(value,label);checks.push(label);};
  try {
    let ready=false;
    for(let i=0;i<45;i++) {
      if(server.exitCode!==null) throw new Error('R exited: '+log);
      try {const r=await fetch(url,{signal:AbortSignal.timeout(600)});if(r.ok){ready=true;break;}}catch{}
      await new Promise(r=>setTimeout(r,200));
    }
    assert(ready,'Shiny did not respond');
    browser=await chromium.launch({headless:true,...(process.env.QA_BROWSER?{channel:process.env.QA_BROWSER}:{})});
    const page=await browser.newPage({viewport:{width:1586,height:992},acceptDownloads:true});
    const errors=[];page.on('pageerror',e=>errors.push(e.message));
    await page.goto(url,{waitUntil:'networkidle'});
    await page.waitForSelector('.heat-cell');
    await page.waitForFunction(()=>document.querySelector('#priority_map canvas')?.width>0);
    check(await page.title()==='Conservation priorities | Victoria','Page identity');
    check(await page.locator('.heat-cell').count()===32,'Two initial areas, sixteen actions');
    await page.screenshot({path:'docs/qa-explore.png',fullPage:true});
    // Resolve a real polygon location through the rendered map, then use a physical click.
    const point=await page.evaluate(()=>{
      const map=HTMLWidgets.find('#priority_map').getMap();
      const layers=Object.values(map._layers);
      const layer=layers.find(l=>l.options?.layerId==='unit375' && l.getBounds);
      const p=map.latLngToContainerPoint(layer.getBounds().getCenter());
      return {x:p.x,y:p.y};
    });
    await page.locator('#priority_map').click({position:point});
    await page.waitForFunction(()=>document.querySelector('#area_detail h2')?.textContent!=='Unit 668');
    check(true,'Map polygon click updates area selection');
    await page.locator('[data-area="unit375"][data-action="Control Cats"]').click();
    await page.waitForFunction(()=>document.querySelector('#area_detail h2')?.textContent==='Unit 375' && document.querySelector('#action').value==='Control Cats');
    check(/88\s*\/\s*100/.test(await page.locator('#area_detail .rank-value').textContent()),'Heatmap updates area, action and rank');
    await page.locator('#extent_unit input[value="ha"]').check();
    await page.waitForFunction(()=>document.querySelector('.comparison-column .extent-label strong')?.textContent.includes('ha'));
    check(true,'Extent toggle updates units');
    await page.locator('#clear').click();
    await page.waitForSelector('.comparison-section .empty-state');
    await page.locator('#pin').click();
    await page.waitForSelector('.pinned-row');
    check(await page.locator('.pinned-row').count()===1,'Clear and pin controls');
    const areaInput=page.locator('#area-selectized');
    await areaInput.fill('925');
    await page.locator('.selectize-dropdown .option[data-value="unit925"]').click();
    await page.waitForSelector('#area_detail .empty-state');
    check((await page.locator('#area_detail').textContent()).includes('No action record'),'Missing record explained');
    await page.locator('#pin').click();
    await page.waitForFunction(()=>document.querySelectorAll('.pinned-row').length===2);
    const downloadPromise=page.waitForEvent('download');
    await page.locator('#download_compare').click();const dl=await downloadPromise;
    const csv=fs.readFileSync(await dl.path(),'utf8');
    check(csv.includes('unit925') && csv.includes('No action record') && csv.includes('SMP4'),'CSV export preserves missing records and provenance');
    await page.locator('#reset').click();
    await page.waitForFunction(()=>document.querySelector('#area_detail h2')?.textContent==='Unit 668');
    check(await page.locator('#action').inputValue()==='Control Foxes','Reset restores map action and focus');
    await page.locator('[data-page="progress"]').click();
    await page.waitForSelector('#target_table table');
    await page.waitForFunction(()=>document.querySelector('#target_gap img')?.complete);
    const yearInput=page.locator('#year-selectized');await yearInput.click();
    await page.locator('.selectize-dropdown .option[data-value="2018-19"]').click();
    await page.waitForFunction(()=>document.querySelector('#target_table')?.textContent.includes('327,382'));
    check(true,'Year selection updates target values');
    await yearInput.click();await page.locator('.selectize-dropdown .option[data-value="2021-22"]').click();
    await page.waitForFunction(()=>document.querySelector('#target_table')?.textContent.includes('1,632,390'));
    await page.locator('#trend_action-selectized').click();
    await page.locator('.selectize-dropdown .option[data-value="Weed control"]').click();
    await page.waitForTimeout(400);
    check(await page.locator('#trend_action').inputValue()==='Weed control','Temporal action filter');
    await page.locator('#trend_action-selectized').click();
    await page.locator('.selectize-dropdown .option[data-value="All actions"]').click();
    await page.waitForTimeout(500);
    await page.screenshot({path:'docs/qa-progress.png',fullPage:true});
    await page.locator('[data-page="sources"]').click();
    check(await page.locator('.reading-page').isVisible(),'Sources view opens');
    await page.screenshot({path:'docs/qa-sources.png',fullPage:true});
    check(await page.locator('.shiny-output-error').count()===0,'No Shiny output errors');
    check(errors.length===0,'No browser JavaScript exceptions');
    await page.setViewportSize({width:390,height:844});
    await page.locator('[data-page="explore"]').click();
    await page.waitForTimeout(600);
    check(await page.evaluate(()=>{
      const m=HTMLWidgets.find('#priority_map').getMap();
      return m.getBounds().contains([-37,145]);
    }),'Map retains Victoria after mobile resize and navigation');
    await page.screenshot({path:'docs/qa-mobile.png',fullPage:true});
    check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+2),'No whole-page mobile overflow');
    console.log(JSON.stringify({url,checks,errors},null,2));
    fs.writeFileSync('docs/browser-results.json',JSON.stringify({viewport:[1586,992],mobile:[390,844],checks,errors},null,2));
  } finally {
    if(browser)await browser.close();server.kill();fs.writeFileSync('docs/qa-server.log',log);
  }
})().catch(e=>{console.error(e);process.exitCode=1;});
