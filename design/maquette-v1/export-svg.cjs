const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('C:/Users/Nathan/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'});
 const page=await browser.newPage();
 const fonts=['Lora','Manrope'].map(f=>({family:f,data:fs.readFileSync(path.join(__dirname,'fonts',f+'.ttf')).toString('base64')}));
 await page.setContent('<style>'+fonts.map(f=>`@font-face{font-family:${f.family};src:url(data:font/ttf;base64,${f.data});font-weight:100 900}`).join('')+'</style><span style="font-family:Lora">A</span><span style="font-family:Manrope">A</span>');
 await page.evaluate(()=>document.fonts.ready);
 const specs=JSON.parse(fs.readFileSync(path.join(__dirname,'native-specs.json'),'utf8'));
 const destination=path.join(__dirname,'figma-svg');fs.mkdirSync(destination,{recursive:true});
 for(const spec of specs){
  const svg=await page.evaluate(({spec,fonts})=>{
   const esc=v=>String(v).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
   const ctx=document.createElement('canvas').getContext('2d');let counter=0;const clips=[];
   function render(n){
    const s=n.s;const name=esc(n.name||n.tag||'Calque');
    if(n.kind==='svg')return `<g data-name="${name}" transform="translate(${n.x} ${n.y})" opacity="${s.opacity??1}">${n.svg}</g>`;
    if(n.kind==='text'){
     ctx.font=`${s.weight} ${s.size}px '${s.font}'`;
     const measure=t=>ctx.measureText(t).width+Math.max(0,t.length-1)*s.letter;
     const lines=[];for(const paragraph of n.text.split('\n')){let line='';for(const word of paragraph.split(/\s+/)){const test=line?line+' '+word:word;if(measure(test)>n.w+2&&line){lines.push(line);line=word;}else line=test;}lines.push(line);}
     const metrics=ctx.measureText('Hgj');const ascent=metrics.fontBoundingBoxAscent||s.size*.8,descent=metrics.fontBoundingBoxDescent||s.size*.2;
     let baseline=n.y+(s.line-ascent-descent)/2+ascent;if(s.display==='flex'&&n.h>s.line*1.5)baseline+=(n.h-lines.length*s.line)/2;
     const anchor=s.align==='center'?'middle':s.align==='right'?'end':'start';const x=n.x+(anchor==='middle'?n.w/2:anchor==='end'?n.w:0);
     const text=lines.map((line,i)=>`<text x="${x}" y="${baseline+i*s.line}" font-family="${s.font}" font-weight="${s.weight}" font-size="${s.size}" letter-spacing="${s.letter}" text-anchor="${anchor}" fill="${s.color}" opacity="${s.opacity??1}">${esc(line)}</text>`).join('');
     const underline=n.name==='active'&&n.tag==='a'?`<path d="M${n.x} ${n.y+n.h-3}h${n.w}" stroke="#a16543" stroke-width="3"/>`:'';
     return `<g data-name="${name}">${text}${underline}</g>`;
    }
    const transparent=s.bg==='rgba(0, 0, 0, 0)';let body=transparent?'':`<rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="${s.r||0}" fill="${s.bg}"/>`;
    if(s.bw){const bs=s.bs||[s.bw,s.bw,s.bw,s.bw];const positions=[[n.x,n.y,n.x+n.w,n.y],[n.x+n.w,n.y,n.x+n.w,n.y+n.h],[n.x,n.y+n.h,n.x+n.w,n.y+n.h],[n.x,n.y,n.x,n.y+n.h]];if(bs.every(v=>v===bs[0]))body+=`<rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="${s.r||0}" fill="none" stroke="${s.border}" stroke-width="${s.bw}"/>`;else bs.forEach((w,i)=>{if(w)body+=`<path d="M${positions[i][0]} ${positions[i][1]}L${positions[i][2]} ${positions[i][3]}" stroke="${s.border}" stroke-width="${w}"/>`;});}
    const children=(n.children||[]).map(render).join('');let clip='';if(s.overflow==='hidden'){const id='clip'+counter++;clips.push(`<clipPath id="${id}"><rect x="${n.x}" y="${n.y}" width="${n.w}" height="${n.h}" rx="${s.r||0}"/></clipPath>`);clip=` clip-path="url(#${id})"`;}
    return `<g data-name="${name}" opacity="${s.opacity??1}">${body}<g${clip}>${children}</g></g>`;
   }
   const body=render(spec.tree);const css=fonts.map(f=>`@font-face{font-family:${f.family};src:url(data:font/ttf;base64,${f.data});font-weight:100 900}`).join('');
   return `<svg xmlns="http://www.w3.org/2000/svg" width="${spec.tree.w}" height="${spec.tree.h}" viewBox="0 0 ${spec.tree.w} ${spec.tree.h}"><title>${esc(spec.title)} — Culture Artistique</title><defs><style>${css}</style>${clips.join('')}</defs>${body}</svg>`;
  },{spec,fonts});
  fs.writeFileSync(path.join(destination,spec.id+'.svg'),svg);
 }
 await browser.close();console.log(specs.length+' planches SVG exportées, textes et illustrations vectoriels.');
})();
