// Optional repeatable browser harness. Install Playwright separately.
const {spawn}=require('node:child_process');
const fs=require('node:fs');const assert=require('node:assert/strict');
const path=require('node:path'),os=require('node:os');
const out=process.env.QA_OUTPUT||path.join(os.tmpdir(),'victoria-landscape-qa');fs.mkdirSync(out,{recursive:true});
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const port=Number(process.env.QA_PORT||7391),url=`http://127.0.0.1:${port}`;
(async()=>{
 const server=spawn(process.env.RSCRIPT||'Rscript',['-e',`shiny::runApp(".",host="127.0.0.1",port=${port},launch.browser=FALSE)`],{cwd:process.cwd(),env:process.env,windowsHide:true});
 let log='',browser;server.stdout.on('data',d=>log+=d);server.stderr.on('data',d=>log+=d);
 const checks=[],check=(ok,label)=>{assert(ok,label);checks.push(label)};
 try {
  let ready=false;for(let i=0;i<80;i++){try{ready=(await fetch(url)).ok;if(ready)break}catch{}await new Promise(r=>setTimeout(r,250))}assert(ready,'Shiny did not start');
  browser=await chromium.launch({headless:true,...(process.env.QA_BROWSER?{channel:process.env.QA_BROWSER}:{})});
  const page=await browser.newPage({viewport:{width:1600,height:1000},acceptDownloads:true});const errors=[],consoleMessages=[];page.on('pageerror',e=>errors.push(e.message));
  page.on('console',m=>{if(['error','warning'].includes(m.type()))consoleMessages.push({level:m.type(),message:m.text(),url:m.location().url})});
  await page.goto(url);await page.waitForSelector('.heat-cell');
  check((await page.locator('.priority-intro .caption').innerText()).includes('financial return.'),'Complete model explanation survives Windows text encoding');
  check(await page.locator('.heat-cell').count()===32,'Retained 16-action explorer');
  check(await page.locator('#map_metric,#extent_unit,.comparison-section,.extent-row').count()===0,'Priority threshold controls and bars removed');
  await page.locator('[data-page="landscape"]').click();await page.locator('#land_focus h2').waitFor();
  check((await page.locator('#land_focus').innerText()).includes('45.4%'),'Prepared reference value rendered');
  await page.locator('#land_area-selectized').click();await page.locator('#land_area-selectized').press('Backspace');await page.locator('#land_area-selectized').type('925');
  await page.locator('.selectize-dropdown .option[data-value="unit925"]').click();
  await page.waitForFunction(()=>document.querySelector('#land_focus h2')?.textContent==='Unit 925');
  await page.locator('[data-page="explore"]').first().click();await page.waitForFunction(()=>document.querySelector('#area_detail h2')?.textContent==='Unit 925');
  check(/no action record/i.test(await page.locator('#area_detail').innerText()),'Shared selection retains missing SMP action');
  await page.locator('[data-page="landscape"]').click();
  for(const [id,value] of [['land_class','17'],['land_metric','change'],['start_epoch','2010_2015']]){
   await page.locator(`#${id}-selectized`).click();await page.locator(`.selectize-dropdown .option[data-value="${value}"]`).click();
  }
  await page.waitForFunction(()=>document.querySelector('#land_map_title')?.textContent.includes('2010 to 2015')&&document.querySelector('#land_map_caption')?.textContent.includes('percentage points'));
  check((await page.locator('#land_focus').innerText()).includes('Water'),'Class and epoch controls update evidence');
  await page.locator('#land_pin').click();await page.locator('#land_pinned [data-remove="unit925"]').waitFor();
  const download=page.waitForEvent('download');await page.locator('#download_landcover').click();const file=await(await download).path();const csv=fs.readFileSync(file,'utf8');
  check(csv.trim().split('\n').length===400&&csv.includes('VLCTS2020-')&&csv.includes('unit925'),'All-epoch separate-unit CSV with provenance');
  await page.locator('.tableau-help > summary').click();
  const workbook=page.waitForEvent('download');await page.locator('#download_tableau').click();const book=fs.readFileSync(await(await workbook).path());check(book.subarray(0,2).toString()==='PK','Portable workbook download from troubleshooting');
  check(await page.locator('.shiny-output-error').count()===0&&errors.length===0,'No output or JavaScript errors');
  check(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+2),'Desktop page fits viewport');
  await page.screenshot({path:path.join(out,'landscape.png'),fullPage:true});
  fs.writeFileSync(path.join(out,'browser-results.json'),JSON.stringify({date:new Date().toISOString(),checks,errors,consoleMessages},null,2));console.log(checks);
 }finally{if(browser)await browser.close();server.kill();fs.writeFileSync(path.join(out,'server.log'),log)}
})().catch(e=>{console.error(e);process.exitCode=1});
