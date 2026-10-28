import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
const config=JSON.parse(read('shared/radar.json'));
const base=process.env.PAGES_BASE_PATH||'/kalradar/';
if(!/^\/[a-zA-Z0-9/_-]*\/$/.test(base))throw Error('Invalid Pages base path');
const api='https://keradar-parallel.gentlevale3.chatgpt.site';
let html=read('src/index.html').replace('<head>','<head><base href="'+base+'">')
 .replace('/*LEAFLET_CSS*/',read('vendor/leaflet.css'))
 .replace('/*LEAFLET_JS*/',read('vendor/leaflet.js').replaceAll('</script','<\\/script'))
 .replace('/*SHARED_CONFIG*/',JSON.stringify(config).replaceAll('<','\\u003c'))
 .replace("const API_BASE='';",'const API_BASE='+JSON.stringify(api)+';')
 .replaceAll('href="/app-icon.png','href="app-icon.png')
 .replaceAll('href="/apple-touch-icon.png','href="apple-touch-icon.png')
 .replaceAll('src="/app-icon.png','src="app-icon.png')
 .replace("register('/sw.js'","register('sw.js'");
const out=path.join(root,'pages');
fs.mkdirSync(path.join(out,'privacy'),{recursive:true});
for(const name of ['index.html','404.html','privacy/index.html'])fs.writeFileSync(path.join(out,name),html);
for(const name of ['app-icon.png','apple-touch-icon.png'])fs.copyFileSync(path.join(root,'assets/app-icon.png'),path.join(out,name));
fs.writeFileSync(path.join(out,'.nojekyll'),'');
const cache='kalradar-pages-'+config.version+'-'+config.build;
fs.writeFileSync(path.join(out,'sw.js'),`const CACHE=${JSON.stringify(cache)};self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./','app-icon.png'])).then(()=>self.skipWaiting())));self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('kalradar-pages-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));self.addEventListener('fetch',e=>{const u=new URL(e.request.url),scope=new URL(self.registration.scope);if(e.request.method==='GET'&&u.origin===scope.origin&&u.pathname.startsWith(scope.pathname)&&e.request.mode==='navigate')e.respondWith(fetch(e.request).catch(()=>caches.match(scope.href)))});`);
console.log('Built GitHub Pages frontend at '+out+'; API '+api);
