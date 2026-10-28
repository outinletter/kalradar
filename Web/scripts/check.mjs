import assert from'node:assert/strict';import {config,decode,retryDelay,includes,decodeRoute,mergeFlights,routeCandidates,routeKey}from'../worker/index.js';
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

assert.deepEqual(mergeFlights([{id:'ABC123',callsign:'KAL42',latitude:1,longitude:2,timestamp:'2026-10-27T00:00:00Z',registration:'HL123'},{id:'abc123',callsign:'KAL42',latitude:3,longitude:4,timestamp:'2026-10-27T00:01:00Z'},{id:'def456',callsign:'KAL43',latitude:37,longitude:126}]).map(f=>[f.id,f.latitude,f.registration]),[['abc123',3,'HL123'],['def456',37,undefined]]);
assert.equal(decode({ac:[{hex:'abc123',flight:'KAL42',lat:40,lon:-74}]},{...config.providers[2],globalScope:true}).length,1);
const label=Function(html.match(/function label\(f\)\{[^\n]+?(?=function node)/)[0]+';return label')();
for(const [input,expected]of[['KE42','KE042'],['KE7','KE007'],['KE1234','KE1234'],['KE42A','KE042A']])assert.equal(label({number:input}),expected);
const validSchedules=Function('CONFIG',html.match(/function validSchedules\(catalog\)\{[\s\S]*?\n\}/)[0]+';return validSchedules')(config);
assert.throws(()=>validSchedules({schemaVersion:2,seasons:[]}));
const fixture={schemaVersion:1,seasons:[{id:'test-winter',title:'TEST',validFrom:'2026-10-25',validThrough:'2027-03-27',updatedAt:'2026-10-27',sourceURL:'https://example.org/test',flights:[{number:'KE42',origin:'ICN',destination:'JFK'}]}]};
assert.equal(validSchedules(fixture).seasons.length,1);assert.throws(()=>validSchedules({...fixture,seasons:[{...fixture.seasons[0],validFrom:'2026-02-30'}]}));
const savedFetch=globalThis.fetch;const requested=[];
globalThis.fetch=async url=>{requested.push(String(url));if(String(url).includes('opensky'))return new Response(JSON.stringify({states:[['abc123','KAL42','KR',1793059200,1793059200,126.5,37.5,10000,false,200,90,1]]}));return new Response(JSON.stringify({now:1793059300,ac:[{hex:'abc123',flight:'KAL42',lat:37.5,lon:126.5,seen_pos:0,r:'HL123'},{hex:'def456',flight:'KAL43',lat:37.5,lon:126.5,seen_pos:1}]}))};
try{const isolated=await import('../worker/index.js?aggregation-test='+Date.now());const response=await isolated.default.fetch(new Request('https://test.invalid/api/positions'),{},{}),result=await response.json();assert.equal(result.flights.length,2);assert.equal(requested.length,3);assert.match(result.provider,/OpenSky.*ADSB.lol.*adsb.fi/);assert(requested[2].includes('/api/v2/icao/'));}finally{globalThis.fetch=savedFetch}
console.log('PASS three-provider aggregation, global ICAO lookup, freshest deduplication, padded KE labels and schedule validation');

assert.equal(label({number:'41'}),'KE041');assert.equal(label({number:'7A'}),'KE007A');
const trackSource=html.match(/function trackSegments\(points\)\{[^\n]+/)[0];
const trackSegments=Function(trackSource+';return trackSegments')();
assert.equal(trackSegments([{latitude:37,longitude:126,time:1000},{latitude:38,longitude:127,time:31000}]).length,1);
assert.equal(trackSegments([{latitude:37,longitude:126,time:1000},{latitude:38,longitude:127,time:1900000}]).length,0);
assert.equal(trackSegments([{latitude:37,longitude:179,time:1000},{latitude:38,longitude:-179,time:31000}]).length,0);
console.log('PASS bare number KE041 formatting and observed track gap/date-line segmentation');

const timeLabels=Function(html.match(/function timeLabels\(f\)\{[\s\S]*?\n\}/)[0]+';return timeLabels')();
assert.deepEqual(timeLabels({}),{departure:'미상',arrival:'미상'});
const sameZone=timeLabels({departureTime:'2026-10-27T01:00:00Z',estimatedArrivalTime:'2026-10-27T03:00:00Z',departureTimeZone:'Asia/Seoul',arrivalTimeZone:'Asia/Seoul'});assert.match(sameZone.departure,/10:00/);assert(!sameZone.departure.includes('2026-'));
const cross=timeLabels({departureTime:'2026-10-26T22:00:00Z',estimatedArrivalTime:'2026-10-27T03:00:00Z',departureTimeZone:'Asia/Seoul',arrivalTimeZone:'America/Los_Angeles'});assert.match(cross.departure,/2026-10-27 07:00/);assert.match(cross.arrival,/2026-10-26 20:00/);
const offset=timeLabels({departureTime:'2026-10-27T10:00:00+09:00'});assert.match(offset.departure,/2026-10-27 10:00 UTC\+09:00/);
const overnight=timeLabels({departureTime:'2026-10-27T14:30:00Z',estimatedArrivalTime:'2026-10-27T16:30:00Z',departureTimeZone:'Asia/Seoul',arrivalTimeZone:'Asia/Seoul'});assert.match(overnight.departure,/2026-10-27/);assert.match(overnight.arrival,/2026-10-28/);
console.log('PASS departure/ETA local zones, explicit dates across zones or midnight, offset fallback and unknown times');

assert.deepEqual(new Set(routeCandidates('KAL41')),new Set(['KAL41','KAL041','KAL0041']));assert.equal(routeKey(' kal0041 '),'KAL41');
const retainedHelpers=Function(html.match(/const canonicalCallsign=[^\n]+/)[0]+html.match(/function retainRoutes\(incoming,previous\)\{[^\n]+/)[0]+';return {canonicalCallsign,retainRoutes}')();
const retained=retainedHelpers.retainRoutes([{id:'abc123',callsign:'KAL41',latitude:38}],[{id:'ABC123',callsign:'KAL041',number:'KE41',origin:'ICN',destination:'SEA'}]);assert.equal(retained[0].destination,'SEA');assert.equal(retained[0].latitude,38);assert(!retainedHelpers.retainRoutes([{id:'abc123',callsign:'KAL42'}],[{id:'ABC123',callsign:'KAL41',destination:'SEA'}])[0].destination);
const listSchedules=Function('label','canonicalCallsign',html.match(/function listedFlights\(observed,seasons,today\)\{[\s\S]*?\n\}/)[0]+';return listedFlights')(label,retainedHelpers.canonicalCallsign);
const offlineRows=listSchedules([],fixture.seasons,'2026-10-27');assert.equal(offlineRows.length,1);assert(offlineRows[0].scheduled);assert.equal(offlineRows[0].latitude,undefined);assert.equal(listSchedules([{id:'abc123',number:'KE042',origin:'ICN',destination:'JFK'}],fixture.seasons,'2026-10-27').length,1);assert.equal(listSchedules([],fixture.seasons,'2027-04-01').length,0);
const previousFetch=globalThis.fetch;let lookupCount=0;globalThis.fetch=async url=>{lookupCount++;const key=String(url).split('/').at(-1);return new Response(JSON.stringify(key==='KAL41'?{response:{flightroute:{callsign_icao:'KAL41',callsign_iata:'KE41',origin:{iata_code:'ICN'},destination:{iata_code:'SEA'}}}}:{response:'unknown callsign'}),{status:key==='KAL41'?200:404})};
try{const isolated=await import('../worker/index.js?route-cache-test='+Date.now());const request=key=>new Request('https://test.invalid/api/route?callsign='+key);const responses=await Promise.all([isolated.default.fetch(request('KAL041'),{},{}),isolated.default.fetch(request('KAL41'),{},{})]);for(const response of responses)assert.equal((await response.json()).destination,'SEA');const count=lookupCount;assert.equal((await(await isolated.default.fetch(request('KAL0041'),{},{})).json()).origin,'ICN');assert.equal(lookupCount,count)}finally{globalThis.fetch=previousFetch}
console.log('PASS route retention, canonical candidate lookup/coalescing/cache, offline schedule-only rows, map exclusion and deduplication');

const bootstrap=Function('CONFIG','localStorage','validSchedules',html.match(/let scheduleCatalog=[^\n]+/)[0]+';return scheduleCatalog');
assert.equal(bootstrap({scheduleCatalog:fixture},{getItem:()=>'{"schemaVersion":1,"seasons":[]}'},validSchedules).seasons.length,1);
const newer={...fixture.seasons[0],updatedAt:'2026-10-28',title:'Newer saved original'};
assert.equal(bootstrap({scheduleCatalog:fixture},{getItem:()=>JSON.stringify({schemaVersion:1,seasons:[newer]})},validSchedules).seasons[0].title,newer.title);
validSchedules(config.scheduleCatalog);
console.log('PASS offline bundled schedule bootstrap with empty storage and newer saved originals');
