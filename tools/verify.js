
const fs=require('fs'), path=require('path');
const {I18N_DIRS}=require('./lib_paths.js');
const BASE='en', THRESHOLD=0.6;
const flat=(o,p,out)=>{out=out||{};p=p||'';
  for(const k of Object.keys(o)){const v=o[k];
    if(v&&typeof v==='object'&&!Array.isArray(v))flat(v,p+k+'.',out);
    else if(['string','number','boolean'].includes(typeof v))out[p+k]=String(v);}
  return out;};
const ph=s=>(String(s).match(/\{[^}]+\}/g)||[]).sort().join('|');
const en=flat(JSON.parse(fs.readFileSync(path.join(I18N_DIRS[0],BASE+'.json'),'utf8')),'',{});
const enKeys=Object.keys(en);
let fail=0;
for(const dir of I18N_DIRS){
  const p=path.join(dir,'zh-Hans.json');
  if(!fs.existsSync(p)){console.log('['+dir+'] absent');continue;}
  let raw, j;
  try{raw=fs.readFileSync(p,'utf8');j=JSON.parse(raw);}catch(e){console.log('['+dir+'] INVALID JSON: '+e.message);fail++;continue;}
  const t=flat(j,'',{});
  const covered=enKeys.filter(k=>t[k]!==undefined);
  const ratio=covered.length/enKeys.length;
  const registered=ratio>=THRESHOLD;
  const incomplete=covered.length<enKeys.length;
  const phBad=enKeys.filter(k=>t[k]!==undefined&&ph(en[k])!==ph(t[k]));
  const cjk=Object.values(t).filter(v=>/[\u4e00-\u9fff]/.test(v)).length;
  console.log('== '+dir);
  console.log('   keys='+Object.keys(t).length+' covered='+covered.length+'/'+enKeys.length+' ratio='+(ratio*100).toFixed(2)+'%');
  console.log('   REGISTERED='+registered+' (threshold '+(THRESHOLD*100)+'%)  incomplete='+incomplete+'  name='+JSON.stringify(j.name));
  console.log('   values containing CJK='+cjk+'  placeholderMismatch='+phBad.length);
  if(phBad.length) {console.log('   e.g. '+phBad.slice(0,3).join(', ')); fail++;}
  if(!registered){fail++;}
}
console.log(fail===0?'VERIFY: PASS':'VERIFY: FAIL ('+fail+' issue(s))');
