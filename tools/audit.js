
const fs=require('fs');
const flat=(o,p,out)=>{out=out||{};p=p||'';
  for(const k of Object.keys(o)){const v=o[k];
    if(v&&typeof v==='object'&&!Array.isArray(v))flat(v,p+k+'.',out);
    else if(['string','number','boolean'].includes(typeof v))out[p+k]=String(v);}
  return out;};
const en=flat(JSON.parse(fs.readFileSync('resources/app/.vite/i18n/en.json','utf8')),'',{});
const zh=flat(JSON.parse(fs.readFileSync('_zh_patch/out/zh-Hans.json','utf8')),'',{});
const keys=Object.keys(en);
const CJK=/[\u4e00-\u9fff]/;
const noCJK=keys.filter(k=>!CJK.test(zh[k]||''));
console.log('== coverage ==', keys.filter(k=>zh[k]!==undefined).length+'/'+keys.length);
console.log('== no-CJK values:', noCJK.length);
noCJK.slice(0,40).forEach(k=>console.log('   '+k+' = '+JSON.stringify(zh[k])));
const mdBad=keys.filter(k=>((en[k].match(/\*\*/g)||[]).length!==((zh[k]||'').match(/\*\*/g)||[]).length));
const tickBad=keys.filter(k=>((en[k].match(/\x60/g)||[]).length!==((zh[k]||'').match(/\x60/g)||[]).length));
const nlBad=keys.filter(k=>((en[k].match(/\n/g)||[]).length!==((zh[k]||'').match(/\n/g)||[]).length));
console.log('== markdown ** mismatch:',mdBad.length, mdBad.slice(0,5));
console.log('== backtick mismatch:',tickBad.length, tickBad.slice(0,5));
console.log('== newline mismatch:',nlBad.length, nlBad.slice(0,5));
const short=keys.filter(k=>en[k].length>=80 && (zh[k]||'').length/en[k].length<0.18);
console.log('== suspiciously short (en>=80, ratio<0.18):',short.length);
short.slice(0,6).forEach(k=>console.log('   '+k+'\n     EN: '+en[k].slice(0,140)+'\n     ZH: '+zh[k].slice(0,90)));
const same=keys.filter(k=>zh[k]===en[k]&&/[A-Za-z]{4,}/.test(en[k]));
console.log('== identical to EN (has words):',same.length);
console.log('== avg len en/zh:', Math.round(keys.reduce((a,k)=>a+en[k].length,0)/keys.length), Math.round(keys.reduce((a,k)=>a+(zh[k]||'').length,0)/keys.length));
