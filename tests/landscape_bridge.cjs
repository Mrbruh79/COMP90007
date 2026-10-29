const assert=require('node:assert/strict');
const {LandscapeBridge,PARAMETERS}=require('../www/tableau.js');
const base={focus:'unit668',compare1:'unit375',compare2:'',compare3:'',class:'Treed native vegetation',start:'1985-1990',end:'2015-2019'};
const params=()=>[...Object.entries(PARAMETERS).map(([k,name])=>({name,currentValue:{value:base[k]}})),{name:'Data release',currentValue:{value:'release1'}}];
(async()=>{
 const calls=[],states=[];let release;
 const client={getParametersAsync:async()=>params(),changeParameterValueAsync:async(name,value)=>{calls.push([name,value]);if(value==='unit1')await new Promise(r=>release=r)}};
 const b=new LandscapeBridge(client,(state)=>states.push(state));
 b.update({...base,focus:'unit1'});const connecting=b.connect('release1');
 while(!release)await new Promise(r=>setImmediate(r));
 b.update({...base,focus:'unit2',compare1:''});release();await connecting;
 assert.equal(b.applied['Main area'],'unit2');assert(calls.some(([n,v])=>n==='Additional area 1 (optional)'&&v===''));
 const n=calls.length;await b.update({...base,focus:'unit2',compare1:''});assert.equal(calls.length,n);
 b.close();await b.update({...base,focus:'unit3'});assert.equal(calls.length,n);
 for(const [name,data] of [['release mismatch',params().map(p=>p.name==='Data release'?{...p,currentValue:{value:'old'}}:p)],['missing control',params().filter(p=>p.name!=='Cover type')]]){
  const x=new LandscapeBridge({getParametersAsync:async()=>data},()=>{});await assert.rejects(x.connect('release1'));console.log('PASS',name);
 }
 const x=new LandscapeBridge({getParametersAsync:async()=>params(),changeParameterValueAsync:async()=>{throw Error('network')}},s=>states.push(s));await x.connect('release1');await x.update({...base,focus:'unit9'});assert(states.includes('error'));
 console.log('PASS queued latest state, empty comparison clearing, deduplication, closed view and network failure');
})().catch(e=>{console.error(e);process.exitCode=1});
