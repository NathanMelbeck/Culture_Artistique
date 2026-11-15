const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require('C:/Users/Nathan/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright');
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'});
 const page=await browser.newPage({viewport:{width:1440,height:1000},deviceScaleFactor:1});
 const manifest=JSON.parse(fs.readFileSync(path.join(__dirname,'manifest.json'),'utf8'));
 const previews=path.join(__dirname,'previews');fs.mkdirSync(previews,{recursive:true});
 const results=[];const nativeSpecs=[];
 for(const screen of manifest.screens){
  await page.goto(pathToFileURL(path.join(__dirname,'screens',screen.id+'.html')).href);
  await page.evaluate(async()=>{await document.fonts.ready;for(const el of document.querySelectorAll('*'))if(getComputedStyle(el).transform!=='none')el.style.transform='none';for(const el of document.querySelectorAll('.key'))el.textContent='Ctrl K';});
  await page.screenshot({path:path.join(previews,screen.id+'.png'),fullPage:true});
  const measures=await page.evaluate(()=>({height:document.querySelector('.screen').scrollHeight,width:document.querySelector('.screen').scrollWidth,overflow:[...document.querySelectorAll('.screen *')].filter(e=>e.getBoundingClientRect().right>1442).map(e=>({tag:e.tagName,cls:e.className})).slice(0,8)}));
  results.push({screen:screen.id,...measures});
  const tree=await page.evaluate(()=>{
   const round=v=>Math.round(v*100)/100;
   const bounds=e=>{const r=e.getBoundingClientRect();return {x:round(r.x),y:round(r.y),w:round(r.width),h:round(r.height)}};
   function capture(el){
    const cs=getComputedStyle(el),b=bounds(el);if(b.w<.1||b.h<.1||cs.display==='none'||cs.visibility==='hidden')return null;
    const s={bg:cs.backgroundColor,color:cs.color,border:cs.borderTopColor,bw:parseFloat(cs.borderTopWidth)||0,r:parseFloat(cs.borderTopLeftRadius)||0,font:cs.fontFamily.includes('Lora')?'Lora':'Manrope',weight:parseInt(cs.fontWeight)||400,size:parseFloat(cs.fontSize),line:parseFloat(cs.lineHeight)||parseFloat(cs.fontSize)*1.25,letter:parseFloat(cs.letterSpacing)||0,align:cs.textAlign,opacity:parseFloat(cs.opacity),display:cs.display,direction:cs.flexDirection,overflow:cs.overflow,position:cs.position};
    s.bs=[cs.borderTopWidth,cs.borderRightWidth,cs.borderBottomWidth,cs.borderLeftWidth].map(v=>parseFloat(v)||0);s.bw=Math.max(...s.bs);s.border=[cs.borderTopColor,cs.borderRightColor,cs.borderBottomColor,cs.borderLeftColor][s.bs.findIndex(v=>v>0)]||cs.borderTopColor;
    const node={kind:'frame',name:el.className?.baseVal!==undefined?'svg':String(el.className||el.tagName.toLowerCase()),tag:el.tagName.toLowerCase(),...b,s};
    if(el.tagName.toLowerCase()==='svg'){node.kind='svg';node.svg=el.outerHTML.replaceAll('currentColor',cs.color).replace(/width="[^"]*"/,'width="'+b.w+'"').replace(/height="[^"]*"/,'height="'+b.h+'"');return node;}
    if(el.tagName==='A'){const target=el.getAttribute('href');if(target&&!target.startsWith('#'))node.target=target.replace('.html','');}
    const descendants=[...el.querySelectorAll('*')];
    const textual=el.textContent.trim()&&descendants.every(d=>['BR','B','STRONG','EM'].includes(d.tagName));
    if(textual){
     node.kind='text';node.text=el.innerText||el.textContent.trim();node.x+=parseFloat(cs.paddingLeft)||0;node.y+=parseFloat(cs.paddingTop)||0;node.w-=((parseFloat(cs.paddingLeft)||0)+(parseFloat(cs.paddingRight)||0));node.h-=((parseFloat(cs.paddingTop)||0)+(parseFloat(cs.paddingBottom)||0));
     if(cs.textTransform==='uppercase')node.text=node.text.toLocaleUpperCase('fr');
     if(cs.backgroundColor!=='rgba(0, 0, 0, 0)'||s.bw){const content={...node,s:{...s,bg:'rgba(0, 0, 0, 0)',bw:0},kind:'text'};return {...node,kind:'frame',...b,children:[content]};}
     return node;
    }
    node.children=[];
    for(const child of el.childNodes){
     if(child.nodeType===Node.ELEMENT_NODE){const part=capture(child);if(part)node.children.push(part);}
     else if(child.nodeType===Node.TEXT_NODE&&child.textContent.trim()){
      const range=document.createRange();range.selectNodeContents(child);const r=range.getBoundingClientRect();
      node.children.push({kind:'text',name:'Label',tag:'text',x:round(r.x),y:round(r.y),w:Math.max(round(r.width),1),h:Math.max(round(r.height),s.line),text:child.textContent.replace(/\s+/g,' ').trim(),s:{...s,bg:'rgba(0, 0, 0, 0)',bw:0}});
     }
    }
    return node;
   }
   return capture(document.querySelector('.screen'));
  });
  nativeSpecs.push({id:screen.id,title:screen.title,tree});
 }
 fs.writeFileSync(path.join(__dirname,'layout-check.json'),JSON.stringify(results,null,2));
 fs.writeFileSync(path.join(__dirname,'native-specs.json'),JSON.stringify(nativeSpecs));
 console.log(JSON.stringify(results));
 await browser.close();
})();
