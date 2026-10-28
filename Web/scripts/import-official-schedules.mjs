import {readFileSync, writeFileSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {gunzipSync} from 'node:zlib';

// Input is an archived response set from the public Korean Air timetable UI.
const root=fileURLToPath(new URL('../../',import.meta.url));
const input=readFileSync(resolve(process.argv[2]));
const archive=JSON.parse((process.argv[2].endsWith('.gz')?gunzipSync(input):input).toString('utf8'));
const groups=new Map();
let direct=0,excluded=0;
for(const response of archive.responses){
 if(response.body.code==='DX.39360')continue; // Official "no flights for this route/date" response.
 if(!Array.isArray(response.body.data))throw Error('Missing timetable data: '+response.url);
 for(const itinerary of response.body.data){
  if(itinerary.connectedFlights?.length!==1){excluded++;continue}
  const segment=itinerary.connectedFlights[0],flight=segment.flight;
  if(flight.marketingAirlineCode!=='KE'||(flight.operatingAirlineCode&&flight.operatingAirlineCode!=='KE')){excluded++;continue}
  // Without an explicit validity range, retain only the dated flight in the response.
  const from=(segment.validityPeriod?.start||flight.departure.dateTime).slice(0,10),through=(segment.validityPeriod?.end||flight.departure.dateTime).slice(0,10);
  if(!/^\d{4}-\d\d-\d\d$/.test(from)||through<from)throw Error('Invalid validity');
  const season=response.queryDate.slice(5,7)>='04'&&response.queryDate.slice(5,7)<='09'?'하계':'동계';
  const key=season+'-'+from+'-'+through;
  const group=groups.get(key)||{id:'ke-published-'+key,title:'대한항공 공식 '+season+' 조회분 · 시즌 전체 아님',validFrom:from,validThrough:through,updatedAt:archive.collectedAt.slice(0,10),sourceURL:'https://www.koreanair.com/flight-status?hl=ko',flights:[]};
  const entry={number:'KE'+flight.marketingFlightNumber.padStart(3,'0'),origin:flight.departure.locationCode,destination:flight.arrival.locationCode};
  if(!group.flights.some(f=>f.number===entry.number&&f.origin===entry.origin&&f.destination===entry.destination))group.flights.push(entry);
  groups.set(key,group);direct++;
 }
}
if(!groups.size)throw Error('No Korean Air operated flights');
const path=resolve(root,'Shared/radar.json'),config=JSON.parse(readFileSync(path,'utf8'));
const kept=config.scheduleCatalog.seasons.filter(s=>!s.id.startsWith('ke-published-'));
const seasons=[...groups.values()].sort((a,b)=>a.validFrom.localeCompare(b.validFrom));
for(const season of seasons)season.flights.sort((a,b)=>a.number.localeCompare(b.number)||a.origin.localeCompare(b.origin));
config.scheduleCatalog.seasons=[...kept,...seasons];
writeFileSync(path,JSON.stringify(config,null,2)+'\n');
console.log(JSON.stringify({responses:archive.responses.length,directRecords:direct,excluded,validityGroups:seasons.length,uniqueRoutes:new Set(seasons.flatMap(s=>s.flights.map(f=>f.number+'|'+f.origin+'|'+f.destination))).size}));
