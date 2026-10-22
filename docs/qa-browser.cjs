const {spawn}=require('child_process');
const fs=require('fs');
const {chromium}=require('C:/Users/arnav/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const server=spawn('C:/Users/arnav/OneDrive/Desktop/Work/Info/tmp/r_runtime/R/app/bin/x64/Rscript.exe',['-e','shiny::runApp(".",host="127.0.0.1",port=7382,launch.browser=FALSE)'],{cwd:process.cwd(),env:{...process.env,R_LIBS_USER:'C:/Users/arnav/OneDrive/Desktop/Work/Info/tmp/r_runtime/library'},windowsHide:true});
 let log='';server.stdout.on('data',d=>{log+=d;});server.stderr.on('data',d=>{log+=d;});
 let browser;
 try{
  for(let i=0;i<50;i++){try{const r=await fetch('http://127.0.0.1:7382',{signal:AbortSignal.timeout(1000)});if(r.ok)break;}catch{} await new Promise(r=>setTimeout(r,200));}
  browser=await chromium.launch({headless:true,executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'});
  const page=await browser.newPage({viewport:{width:1600,height:1000}});
  const errors=[];page.on('pageerror',e=>errors.push(e.message));
  await page.goto('http://127.0.0.1:7382',{waitUntil:'networkidle',timeout:30000});
  await page.waitForSelector('.heat-cell',{timeout:30000});
  await page.screenshot({path:'docs/qa-explore.png',fullPage:true});
  console.log('TITLE',await page.title());console.log('ERROR ELEMENTS',await page.locator('.shiny-output-error').allTextContents());
  console.log('HEAT CELLS',await page.locator('.heat-cell').count());
  await page.locator('[data-page="progress"]').click();
  await page.waitForTimeout(3000);
  await page.screenshot({path:'docs/qa-progress.png',fullPage:true});
  console.log('PROGRESS ERRORS',await page.locator('.shiny-output-error').allTextContents());
  console.log('JS ERRORS',errors);
 }finally{if(browser)await browser.close();server.kill();fs.writeFileSync('docs/qa-server.log',log);console.log(log.slice(-8000));}
})().catch(e=>{console.error(e);process.exitCode=1});

