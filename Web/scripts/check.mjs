import assert from'node:assert/strict';import {config,decode,retryDelay,includes,decodeRoute}from'../worker/index.js';
assert.equal(config.refreshInterval,30);assert.equal(config.demoFlights.length,8);assert(config.demoFlights.every(includes));const sky=config.providers[0],lol=config.providers[1];const flights=decode({states:[['abc','KAL123 ','KR',1700000000,1700000001,126.5,37.5,10000,false,200,90,1],['bad','DAL123','US',1,1,127,37,1,false,1,1,1]]},sky);assert.equal(flights.length,1);assert(Math.abs(flights[0].altitude-32808.4)<.1);assert.deepEqual(decode({states:null},sky),[]);assert.throws(()=>decode({error:'bad'},sky));assert(!includes({callsign:'KALABC',latitude:37,longitude:127}));assert(!includes({callsign:'KAL123',latitude:91,longitude:127}));assert.equal(decode({now:1700000000,ac:[{hex:'abc',flight:'KAL123',lat:37.5,lon:126.5,seen_pos:2},{hex:'abc',flight:'KAL123',lat:37.5,lon:126.5},{hex:'far',flight:'KAL456',lat:0,lon:0}]},lol).length,1);assert.equal(retryDelay(new Headers({'Retry-After':'120'}),1700000000000),120000);assert.equal(retryDelay(new Headers(),1700000000000),3600000);console.log('PASS shared configuration, demo, callsign/coordinate filter, deduplication, provider decoding, radius and rate limits');

assert.deepEqual(decodeRoute({response:{flightroute:{callsign_icao:"KAL123",callsign_iata:"KE123",origin:{iata_code:"ICN"},destination:{iata_code:"BNE"}}}},"KAL123"),{origin:"ICN",destination:"BNE",number:"KE123"});assert.equal(decodeRoute({response:{flightroute:{callsign_icao:"DAL123"}}},"KAL123").origin,null);

const originalFetch=globalThis.fetch;
Object.defineProperty(globalThis,'caches',{configurable:true,get(){throw Error('This Worker is not permitted to access the default cache.')}});
globalThis.fetch=async()=>new Response(JSON.stringify({states:[]}),{headers:{'Content-Type':'application/json'}});
const {default:worker}=await import('../worker/index.js');
try{const r=await worker.fetch(new Request('https://test.invalid/api/positions'),{},{});assert.equal(r.status,200);assert.deepEqual((await r.json()).flights,[]);}finally{globalThis.fetch=originalFetch;delete globalThis.caches;}
const html=await (await import('node:fs/promises')).readFile(new URL('../src/index.html',import.meta.url),'utf8');
const fn=html.match(/async function apiJSON\(response\)\{[\s\S]*?\n\}/)[0];
const apiJSON=Function(fn+';return apiJSON')();
await assert.rejects(apiJSON(new Response('<!DOCTYPE html>',{status:500,headers:{'Content-Type':'text/html'}})),/정상 응답/);
await assert.rejects(apiJSON(new Response('{bad',{headers:{'Content-Type':'application/json'}})),/읽지 못/);
assert.deepEqual(await apiJSON(new Response('{"flights":[]}',{headers:{'Content-Type':'application/json'}})),{flights:[]});
console.log('PASS restricted cache runtime and HTML/malformed JSON error handling');
