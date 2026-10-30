const assert=require('node:assert/strict');
const {LandscapeBridge,PARAMETERS}=require('../www/tableau.js');
const base={focus:'unit668',compare1:'unit375',compare2:'',compare3:'',class:'Treed native vegetation',start:'1985-1990',end:'2015-2019'};
const params=()=>[...Object.entries(PARAMETERS).map(([k,name])=>({name,currentValue:{value:base[k]}})),{name:'Data release',currentValue:{value:'release1'}}];
(async()=>{
 const filters=['AreaSeries','ClassMatch','CompareMatch','EndpointMatch'].map(field=>({fieldId:`[federated.landcover].[none:${field}:nk]`,fieldName:field==='AreaSeries'?'Area':field,filterType:'categorical',isAllSelected:false}));
 const cleared=[];
 const sheet={name:'T04_NetChange',getFiltersAsync:async()=>filters,clearFilterAsync:async name=>{cleared.push(name);filters.find(f=>f.fieldName===name).isAllSelected=true;}};
 const guarded=new LandscapeBridge({activeSheet:{worksheets:[sheet]},getParametersAsync:async()=>params(),changeParameterValueAsync:async()=>{}},()=>{});
 await guarded.connect('release1');assert.deepEqual(cleared,['Area']);
 assert(filters.slice(1).every(f=>!f.isAllSelected));
 // A new manual restriction must also be cleared before changing the focus.
 // The API can still report all selected while its rendered filter changes.
 filters[0].isAllSelected=true;await guarded.update({...base,focus:'unit925'});
 assert.deepEqual(cleared,['Area','Area']);
 await guarded.update({...base,focus:'unit925'});assert.equal(cleared.length,2);
 const broken=new LandscapeBridge({activeSheet:{worksheets:[{...sheet,getFiltersAsync:async()=>{throw Error('filter query failed')}}]},getParametersAsync:async()=>params()},()=>{});
 await assert.rejects(broken.connect('release1'),/filter query failed/);
 console.log('PASS stale area filter cleared on load and selection change; analytical filters preserved');
 const events=new LandscapeBridge({getParametersAsync:async()=>params(),changeParameterValueAsync:async()=>{}},()=>{});
 await events.connect('release1');await events.update(base);
 let resolveEvent;
 const delayed=events.readParameterChange(()=>new Promise(resolve=>{resolveEvent=resolve}));
 await events.update({...base,class:'Water'});
 resolveEvent({name:'Cover type',currentValue:{value:'Built environment'}});
 assert.equal(await delayed,null);assert.equal(events.desired.class,'Water');
 assert.equal(await events.readParameterChange(async()=>({name:'Cover type',currentValue:{value:'Water'}})),null);
 const genuine=await events.readParameterChange(async()=>({name:'Cover type',currentValue:{value:'Built environment'}}));
 assert.equal(genuine.value,'Built environment');assert.equal(events.desired.class,'Built environment');
 assert.equal(await events.readParameterChange(async()=>({name:'Composition view',currentValue:{value:'All cover types'}})),null);
 console.log('PASS delayed Tableau events cannot replace newer Shiny selection; own echoes ignored and genuine external changes retained');
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
