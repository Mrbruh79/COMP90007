const assert = require('node:assert/strict');
const {ProgressBridge} = require('../www/tableau.js');
const params = release => [
  {name:'Data release',currentValue:{value:release}},
  {name:'Selected year',currentValue:{value:'2021-22'}},
  {name:'Selected action',currentValue:{value:'All actions'}}
];
(async () => {
  const calls=[], statuses=[];
  let releaseFirst;
  const first = new Promise(resolve=>{releaseFirst=resolve;});
  const bridge = new ProgressBridge({
    getParametersAsync:async()=>params('release-a'),
    changeParameterValueAsync:async(name,value)=>{
      calls.push([name,value]);
      if(calls.length===1) await first;
    }
  },(...x)=>statuses.push(x));
  bridge.update({year:'2018-19',action:'Weed control'});
  const connected=bridge.connect('release-a');
  await new Promise(setImmediate);
  bridge.update({year:'2020-21',action:'Pest predator control'});
  bridge.update({year:'2021-22',action:'Pest herbivore control'});
  releaseFirst();await connected;
  assert.equal(bridge.applied['Selected year'],'2021-22');
  assert.equal(bridge.applied['Selected action'],'Pest herbivore control');
  assert.equal(statuses.at(-1)[0],'ready');
  const count=calls.length;
  await bridge.update({year:'2021-22',action:'Pest herbivore control'});
  assert.equal(calls.length,count,'unchanged state must not start an event loop');
  const wrong=new ProgressBridge({getParametersAsync:async()=>params('wrong')},()=>{});
  await assert.rejects(wrong.connect('release-a'),/different data release/);
  const incomplete=new ProgressBridge({getParametersAsync:async()=>params('release-a').slice(0,2)},()=>{});
  await assert.rejects(incomplete.connect('release-a'),/missing its selection controls/);
  const failed=[];
  const unavailable=new ProgressBridge({getParametersAsync:async()=>params('release-a'),changeParameterValueAsync:async()=>{throw Error('offline');}},(...x)=>failed.push(x));
  unavailable.desired={year:'2018-19',action:'All actions'};await unavailable.connect('release-a');
  assert.equal(failed.at(-1)[0],'error');
  bridge.close();await bridge.update({year:'2018-19',action:'All actions'});
  assert.equal(calls.length,count,'disposed views must not receive stale updates');
  console.log('PASS queued selections converge to the latest state; duplicate state; release mismatch; missing parameters; network failure; disposed view');
})().catch(error=>{console.error(error);process.exitCode=1;});
