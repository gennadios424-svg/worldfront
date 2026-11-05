import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';

const html=fs.readFileSync(new URL('../index.html',import.meta.url),'utf8');
const match=html.match(/<script>([\\s\\S]*?)<\\/script>/i);
assert(match,'index.html inline simulation script not found');
let source=match[1];
const boot='init();resize();requestAnimationFrame(frame);';
assert(source.includes(boot),'simulation boot sequence changed; update the test harness explicitly');
source=source.replace(boot,'init();window.__WORLD_TEST__={update,teams,get year(){return year},get sim(){return sim}};');

let seed=424242;
const seededMath={};
for(const key of Object.getOwnPropertyNames(Math)) seededMath[key]=Math[key];
seededMath.random=()=>{seed=(seed*1664525+1013904223)>>>0;return seed/4294967296};
const noop=()=>{};
const ctx=new Proxy({}, {get:(o,k)=>k==='createLinearGradient'||k==='createRadialGradient'?()=>({addColorStop:noop}):k==='measureText'?()=>({width:0}):noop,set:(o,k,v)=>(o[k]=v,true)});
const element=()=>({width:0,height:0,style:{},dataset:{},classList:{add:noop,remove:noop,toggle:noop,contains:()=>false},addEventListener:noop,setPointerCapture:noop,getContext:()=>ctx,click:noop});
const els=new Map();
const document={getElementById(id){if(!els.has(id))els.set(id,element());return els.get(id)},createElement(){return element()},querySelectorAll(){return[]},addEventListener:noop,activeElement:{tagName:'BODY'}};
const window={};
const sandbox={window,document,Math:seededMath,console,setTimeout:()=>1,clearTimeout:noop,requestAnimationFrame:noop,addEventListener:noop,devicePixelRatio:1,innerWidth:1280,innerHeight:720};
vm.runInNewContext(source,sandbox,{timeout:120000});
const sim=sandbox.window.__WORLD_TEST__;
assert(sim,'test API was not exposed');
const steps=3120,dt=.25;
for(let i=0;i<steps;i++)sim.update(dt);
const report=sim.teams.map(t=>{
 const complete=t.buildings.filter(b=>b.progress>=.999);
 const counts={};for(const v of t.civilians)counts[v.task]=(counts[v.task]||0)+1;
 return {nation:t.name,year:sim.year,settlements:t.settlements.length,cities:t.cities?.length||0,population:t.civilians.length,adults:t.civilians.filter(v=>v.stage==='adult').length,farms:complete.filter(b=>b.type==='farm').length,houses:complete.filter(b=>b.type==='house').length,factories:complete.filter(b=>b.type==='factory').length,roads:t.settlements.reduce((n,s)=>n+(s.roads||[]).filter(r=>r.progress>.1).length,0),horses:t.horses?.length||0,stock:{wood:+t.resources.wood.toFixed(1),stone:+t.resources.stone.toFixed(1),food:+t.resources.food.toFixed(1)},tasks:counts};
});
console.log(JSON.stringify({seed:424242,simSeconds:sim.sim,year:sim.year,nations:report},null,2));
assert(sim.year>=14,'simulation did not reach Year 14');
assert(report.some(r=>r.settlements>0),'no nation founded a settlement by Year 14');
assert(report.some(r=>r.farms>0&&r.houses>0),'no nation completed both farms and houses by Year 14');
assert(report.every(r=>r.population>=10),'a nation lost most of its population');
