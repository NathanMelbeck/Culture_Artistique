// Exécuté dans Figma Plugin API. SPECS et STATE sont injectés par l'orchestrateur.
const created=[],mutated=[],links=[];
const remember=n=>{created.push(n.id);return n;};
const colorKey=v=>{const p=String(v||'').match(/[\d.]+/g);if(!p||p.length<3)return null;return {hex:'#'+p.slice(0,3).map(n=>Math.round(Number(n)).toString(16).padStart(2,'0')).join(''),color:{r:Number(p[0])/255,g:Number(p[1])/255,b:Number(p[2])/255},alpha:p.length>3?Number(p[3]):1};};
const fontStyle=s=>s.weight>=700?'Bold':s.weight>=600?'SemiBold':s.weight>=500?'Medium':'Regular';
const styleKey=s=>[s.font,fontStyle(s),s.size,s.line,s.letter].join('/');
const hash=s=>{let h=2166136261;for(let i=0;i<s.length;i++)h=Math.imul(h^s.charCodeAt(i),16777619);return(h>>>0).toString(16);};
const textSpecs=n=>n.kind==='text'?[n]:(n.children||[]).flatMap(textSpecs);
const svgSpecs=n=>n.kind==='svg'?[n]:(n.children||[]).flatMap(svgSpecs);
await Promise.all(['Regular','Medium','SemiBold','Bold'].flatMap(style=>['Manrope','Lora'].map(family=>figma.loadFontAsync({family,style}))).concat([figma.loadFontAsync({family:'Inter',style:'Regular'}),figma.loadFontAsync({family:'Inter',style:'Medium'}),figma.loadFontAsync({family:'Inter',style:'Semi Bold'})]));
const page=await figma.getNodeByIdAsync(STATE.pageId||'0:1');
await figma.setCurrentPageAsync(page);
page.name='01 · Maquette desktop';
mutated.push(page.id);
let colorVars={},spaceVars={},radiusVars={},textStyles={};
if(!STATE.collectionId){
 const collection=figma.variables.createVariableCollection('Culture Artistique · Fondations');collection.renameMode(collection.modes[0].modeId,'Éditorial');STATE.collectionId=collection.id;STATE.variables={colors:{},spaces:{},radii:{}};STATE.styles={};
 const colors=new Map();for(const screen of SPECS){const walk=n=>{for(const val of[n.s.bg,n.s.color,n.s.border]){const c=colorKey(val);if(c&&c.alpha>0)colors.set(c.hex,c.color);}for(const child of n.children||[])walk(child);};walk(screen.tree);}
 const names={'#243d37':'Forêt','#f8f6ef':'Ivoire','#fffef8':'Surface','#e9ecdf':'Sauge','#a16543':'Bronze','#718074':'Texte secondaire'};
 for(const[hex,value]of colors){const primitive=figma.variables.createVariable('Primitives/'+hex,collection,'COLOR');primitive.scopes=[];primitive.setValueForMode(collection.modes[0].modeId,value);const variable=figma.variables.createVariable('Couleurs/'+(names[hex]||hex),collection,'COLOR');variable.scopes=['FRAME_FILL','SHAPE_FILL','TEXT_FILL','STROKE_COLOR'];variable.setValueForMode(collection.modes[0].modeId,{type:'VARIABLE_ALIAS',id:primitive.id});variable.setVariableCodeSyntax('WEB',`var(--ca-color-${hex.slice(1)})`);STATE.variables.colors[hex]=variable.id;colorVars[hex]=variable;}
 for(const value of[4,6,7,8,9,10,11,12,13,14,16,18,20,22,24,25,28,30,32,34,35,36,38,40,42,48,52,55,64]){const variable=figma.variables.createVariable('Espacements/'+value,collection,'FLOAT');variable.scopes=['GAP'];variable.setValueForMode(collection.modes[0].modeId,value);variable.setVariableCodeSyntax('WEB',`var(--ca-space-${value})`);STATE.variables.spaces[value]=variable.id;spaceVars[value]=variable;}
 for(const value of[3,4,5,6,7,8,9,10,11,12,13,14,25]){const variable=figma.variables.createVariable('Rayons/'+value,collection,'FLOAT');variable.scopes=['CORNER_RADIUS'];variable.setValueForMode(collection.modes[0].modeId,value);variable.setVariableCodeSyntax('WEB',`var(--ca-radius-${value})`);STATE.variables.radii[value]=variable.id;radiusVars[value]=variable;}
 const styles=new Map();for(const screen of SPECS)for(const spec of textSpecs(screen.tree))styles.set(styleKey(spec.s),spec.s);
 for(const[key,s]of styles){const style=figma.createTextStyle();style.name='CA/'+s.font+'/'+s.size+'/'+fontStyle(s)+'/'+Math.round(s.line);style.fontName={family:s.font,style:fontStyle(s)};style.fontSize=s.size;style.lineHeight={unit:'PIXELS',value:s.line};style.letterSpacing={unit:'PIXELS',value:s.letter};STATE.styles[key]=style.id;textStyles[key]=style;}
 STATE.components={};STATE.svgAssets={};
 const library=remember(figma.createFrame());library.name='Composants · Navigation, cartes et illustrations';library.resize(4600,4600);library.x=100;library.y=5200;library.fills=[];library.clipsContent=false;STATE.componentFrameId=library.id;
}else{
 const entries=Object.entries(STATE.variables.colors);const vars=await Promise.all(entries.map(([,id])=>figma.variables.getVariableByIdAsync(id)));entries.forEach(([key],i)=>colorVars[key]=vars[i]);
 const radii=Object.entries(STATE.variables.radii);const rs=await Promise.all(radii.map(([,id])=>figma.variables.getVariableByIdAsync(id)));radii.forEach(([key],i)=>radiusVars[key]=rs[i]);
 const spaces=Object.entries(STATE.variables.spaces);const ss=await Promise.all(spaces.map(([,id])=>figma.variables.getVariableByIdAsync(id)));spaces.forEach(([key],i)=>spaceVars[key]=ss[i]);
 const styles=Object.entries(STATE.styles);const ts=await Promise.all(styles.map(([,id])=>figma.getStyleByIdAsync(id)));styles.forEach(([key],i)=>textStyles[key]=ts[i]);
}
const library=await figma.getNodeByIdAsync(STATE.componentFrameId);
let masterNumber=library.children.length;
function paint(value){const c=colorKey(value);if(!c||c.alpha===0)return[];let p={type:'SOLID',color:c.color,opacity:c.alpha};if(colorVars[c.hex])p=figma.variables.setBoundVariableForPaint(p,'color',colorVars[c.hex]);return[p];}
function visual(n,s){n.fills=paint(s.bg);n.strokes=s.bw?paint(s.border):[];if(s.bw){n.strokeWeight=s.bw;if(s.bs){n.strokeTopWeight=s.bs[0];n.strokeRightWeight=s.bs[1];n.strokeBottomWeight=s.bs[2];n.strokeLeftWeight=s.bs[3];}}if(s.r&&'cornerRadius'in n){n.cornerRadius=s.r;if(radiusVars[s.r])n.setBoundVariable('cornerRadius',radiusVars[s.r]);}n.opacity=s.opacity??1;}
function masterPosition(n){library.appendChild(n);const index=masterNumber++;n.x=(index%5)*850;n.y=Math.floor(index/5)*440;n.description='Composant réutilisable de la maquette Culture Artistique. Les libellés et illustrations exposés sont modifiables.';}
function svgAsset(spec){const key=hash(spec.svg);if(STATE.svgAssets[key])return figma.getNodeByIdAsync(STATE.svgAssets[key]);const svg=remember(figma.createNodeFromSvg(spec.svg));svg.name='Illustration/'+key;for(const t of svg.findAllWithCriteria({types:['TEXT']}))t.fontName={family:'Manrope',style:'Regular'};const component=remember(figma.createComponentFromNode(svg));masterPosition(component);STATE.svgAssets[key]=component.id;return component;}
const [buttonSet,searchSet]=await Promise.all([figma.importComponentSetByKeyAsync('cc8b558dc7d9684011b6b99ce8e6509399bc836b'),figma.importComponentSetByKeyAsync('715a105916909fcad1d649ed31db27dc26375edd')]);
const buttonMain=buttonSet.children.find(n=>n.name==='Variant=Primary, State=Default, Size=Medium');
const searchMain=searchSet.children.find(n=>n.name==='State=Default, Value Type=Placeholder');
function setTextStyle(node,s){node.fontName={family:s.font,style:fontStyle(s)};const style=textStyles[styleKey(s)];if(style)node.textStyleId=style.id;else{node.fontSize=s.size;node.lineHeight={unit:'PIXELS',value:s.line};node.letterSpacing={unit:'PIXELS',value:s.letter};}node.fills=paint(s.color);node.textAlignHorizontal=s.align==='center'?'CENTER':s.align==='right'?'RIGHT':'LEFT';}
function applyTextData(n,spec){setTextStyle(n,spec.s);n.characters=spec.text;n.textAutoResize='HEIGHT';n.resize(Math.max(spec.w+1,1),Math.max(spec.h,1));}
async function external(spec,isSearch){const n=remember((isSearch?searchMain:buttonMain).createInstance());n.name=isSearch?'Recherche/'+(spec.text||'locale'):'Action/'+(spec.target||'continuer');const texts=textSpecs(spec);const label=texts.map(t=>t.text).join(' ').replace('Ctrl K','').trim();if(isSearch)n.setProperties({'Value#29:2':label});else n.setProperties({'Label#2:0':label+'  →','Has Icon Start#4:128':false,'Has Icon End#4:64':false});n.resize(Math.max(spec.w,1),Math.max(spec.h,1));n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';visual(n,spec.s);for(const t of n.findAllWithCriteria({types:['TEXT']})){setTextStyle(t,{...spec.s,font:'Manrope',weight:isSearch?400:600});}if(spec.target)links.push({id:n.id,target:spec.target});return n;}
function localKey(spec,screen){const cls=spec.name||'';if(spec.tag==='header')return'Navigation/'+(screen.id==='01-accueil'||screen.id==='11-systeme-visuel'?'Accueil':Number(screen.id.slice(0,2))<5?'Cours':screen.id==='10-credits'?'Crédits':'Jeux');if(spec.tag==='footer')return'Pied de page';if(/^(tag|chip|chapter|answer|board-card)( |$)/.test(cls))return'CA/'+cls+'/'+hash(JSON.stringify({bg:spec.s.bg,color:spec.s.color,border:spec.s.border,svgCount:svgSpecs(spec).length}));return null;}
async function build(spec,screen,skipComponent=false){
 if(spec.kind==='svg'){const comp=await svgAsset(spec);const n=remember(comp.createInstance());n.name=spec.name||'Illustration';n.resize(Math.max(spec.w,1),Math.max(spec.h,1));return n;}
 if(spec.kind==='text'){const n=remember(figma.createText());n.name=spec.text.replace(/\s+/g,' ').slice(0,65);applyTextData(n,spec);if(spec.target)links.push({id:n.id,target:spec.target});return n;}
 if(/(^| )button( |$)/.test(spec.name))return external(spec,false);
 if(/(^| )search( |$)/.test(spec.name))return external(spec,true);
 const key=skipComponent?null:localKey(spec,screen);
 if(key){
  let entry=STATE.components[key];
  if(!entry){const built=await build(spec,screen,true);const component=remember(figma.createComponentFromNode(built));component.name=key;masterPosition(component);entry={id:component.id,textProps:[],mediaProps:[]};const ts=component.findAllWithCriteria({types:['TEXT']});ts.forEach((t,i)=>{const prop=component.addComponentProperty('Texte '+(i+1),'TEXT',t.characters);t.componentPropertyReferences={characters:prop};entry.textProps.push(prop);});const assets=Object.values(STATE.svgAssets);const instances=component.findAllWithCriteria({types:['INSTANCE']}).filter(i=>i.mainComponent&&assets.includes(i.mainComponent.id));instances.forEach((n,i)=>{const prop=component.addComponentProperty('Visuel '+(i+1),'INSTANCE_SWAP',n.mainComponent.id);n.componentPropertyReferences={mainComponent:prop};entry.mediaProps.push(prop);});STATE.components[key]=entry;}
  const component=await figma.getNodeByIdAsync(entry.id);const inst=remember(component.createInstance());inst.name=key.split('/').slice(0,2).join('/');const props={};const ts=textSpecs(spec);entry.textProps.forEach((p,i)=>{if(ts[i])props[p]=ts[i].text;});const ss=svgSpecs(spec);for(let i=0;i<entry.mediaProps.length&&i<ss.length;i++){const media=await svgAsset(ss[i]);props[entry.mediaProps[i]]=media.id;}inst.setProperties(props);inst.resize(Math.max(spec.w,1),Math.max(spec.h,1));const it=inst.findAllWithCriteria({types:['TEXT']});it.forEach((t,i)=>{if(ts[i]){setTextStyle(t,ts[i].s);t.textAutoResize='HEIGHT';t.resize(Math.max(ts[i].w+1,1),Math.max(ts[i].h,1));}});if(spec.target)links.push({id:inst.id,target:spec.target});return inst;
 }
 const children=spec.children||[];
 let axis=null;
 const nonoverlap=(a)=>children.every((c,i)=>i===0||c[a]>=(children[i-1][a]+children[i-1][a==='x'?'w':'h'])-.8);
 if(children.length&&children.every(c=>c.s.position!=='absolute')){
  if(nonoverlap('y'))axis='VERTICAL';else if(nonoverlap('x'))axis='HORIZONTAL';
 }
 // Les grilles sont composées de rangées en auto-layout, jamais d'une image aplatie.
 if(spec.s.display==='grid'&&children.length>1&&!axis){
  const rows=[];for(const child of children){let row=rows.find(r=>Math.abs(r.y-child.y)<3);if(!row){row={y:child.y,children:[]};rows.push(row);}row.children.push(child);}
  if(rows.length>1){const replacements=rows.map(row=>{const left=Math.min(...row.children.map(n=>n.x)),right=Math.max(...row.children.map(n=>n.x+n.w)),bottom=Math.max(...row.children.map(n=>n.y+n.h));return{kind:'frame',name:'Rangée',tag:'div',x:left,y:row.y,w:right-left,h:bottom-row.y,s:{...spec.s,bg:'rgba(0, 0, 0, 0)',bw:0,r:0,display:'flex'},children:row.children};});return build({...spec,s:{...spec.s,display:'block'},children:replacements},screen,true);}
 }
 const n=remember(axis?figma.createAutoLayout(axis):figma.createFrame());n.name=spec.name||spec.tag;n.resize(Math.max(spec.w,1),Math.max(spec.h,1));visual(n,spec.s);n.clipsContent=spec.s.overflow==='hidden';
 if(axis){
  n.primaryAxisSizingMode='FIXED';n.counterAxisSizingMode='FIXED';n.itemSpacing=0;if(spec.name==='nav')n.counterAxisAlignItems='CENTER';
  const minX=Math.min(...children.map(c=>c.x)),minY=Math.min(...children.map(c=>c.y)),maxX=Math.max(...children.map(c=>c.x+c.w)),maxY=Math.max(...children.map(c=>c.y+c.h));
  n.paddingLeft=Math.max(0,minX-spec.x);n.paddingTop=Math.max(0,minY-spec.y);n.paddingRight=Math.max(0,spec.x+spec.w-maxX);n.paddingBottom=Math.max(0,spec.y+spec.h-maxY);
  for(const prop of['paddingLeft','paddingTop','paddingRight','paddingBottom']){const v=Math.round(n[prop]);if(Math.abs(v-n[prop])<.02&&spaceVars[v])n.setBoundVariable(prop,spaceVars[v]);}
  let last=axis==='VERTICAL'?minY:minX;
  for(const child of children){const start=axis==='VERTICAL'?child.y:child.x;const gap=start-last;if(gap>.1){const spacer=remember(figma.createFrame());spacer.name='Espacement';spacer.fills=[];spacer.resize(axis==='VERTICAL'?1:gap,axis==='VERTICAL'?gap:1);n.appendChild(spacer);}
   const item=await build(child,screen);const indent=axis==='VERTICAL'?child.x-minX:child.y-minY;
   if(indent>.1){const wrap=remember(figma.createAutoLayout(axis==='VERTICAL'?'HORIZONTAL':'VERTICAL'));wrap.name='Alignement';wrap.fills=[];wrap.resize(axis==='VERTICAL'?Math.max(maxX-minX,child.w):child.w,axis==='VERTICAL'?child.h:Math.max(maxY-minY,child.h));wrap.primaryAxisSizingMode='FIXED';wrap.counterAxisSizingMode='FIXED';if(axis==='VERTICAL')wrap.paddingLeft=indent;else wrap.paddingTop=indent;wrap.appendChild(item);n.appendChild(wrap);}else n.appendChild(item);
   last=start+(axis==='VERTICAL'?child.h:child.w);
  }
 }else for(const child of children){const item=await build(child,screen);n.appendChild(item);item.x=child.x-spec.x;item.y=child.y-spec.y;}
 if(spec.name==='active'&&spec.tag==='a'){const line=remember(figma.createRectangle());line.name='État actif';line.resize(Math.max(spec.w,1),3);line.fills=paint('rgb(161, 101, 67)');n.appendChild(line);if(n.layoutMode!=='NONE')line.layoutPositioning='ABSOLUTE';line.x=0;line.y=spec.h-3;}
 if(spec.target)links.push({id:n.id,target:spec.target});
 return n;
}
STATE.frames=STATE.frames||{};
for(const screen of BUILD_SPECS){if(STATE.frames[screen.id])continue;const frame=await build(screen.tree,screen,true);frame.name=screen.id.slice(0,2)+' / '+screen.title;page.appendChild(frame);const index=Number(screen.id.slice(0,2))-1;frame.x=100+(index%3)*1560;frame.y=100+Math.floor(index/3)*1200;frame.clipsContent=true;STATE.frames[screen.id]=frame.id;}
STATE.links=(STATE.links||[]).concat(links);
return {createdNodeIds:created,mutatedNodeIds:mutated,state:STATE,counts:{frames:Object.keys(STATE.frames).length,components:Object.keys(STATE.components).length,illustrations:Object.keys(STATE.svgAssets).length,styles:Object.keys(STATE.styles).length,variables:Object.keys(STATE.variables.colors).length},bounds:BUILD_SPECS.map(s=>({id:STATE.frames[s.id],name:s.title,width:s.tree.w,height:s.tree.h}))};
