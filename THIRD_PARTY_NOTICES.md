# Reference attribution

The official Flightradar24 Node SDK, `@flightradar24/fr24sdk` 0.1.1, was inspected as an API transport and endpoint reference. This project implements its own native Swift client and does not bundle the SDK. Source repository recorded in SDK package metadata: https://github.com/Flightradar24/fr24api-sdk-js; inspected commit: eb0e74f0943a5aa23d1d3ae6c3eff8e2fad159f3.

## SDK MIT license

MIT License

Copyright (c) 2025 Flightradar24 AB

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Other sources

Flight response field names were checked against the official FR24 API OpenAPI `FlightPositionsFull` schema. API data access is governed by FR24 API subscription terms, not this SDK's MIT software license. MapKit maps and SF Symbols use Apple system frameworks. No proprietary FR24 consumer-app or Korean Air visual assets were copied.
