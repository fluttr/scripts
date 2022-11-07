// https://porkbun.com

let domainNames = $x("//div[@class='row searchResultRowTable']//div[contains(@class, 'availableDomain')]/text()") 

let rawFirstPrices = $x("//div[@class='row searchResultRowTable']/div[contains(@class,'searchResultRowCell')]/span[@class='childContent']/text()") 
function containsDigit(val){return null != val.match("\\d")}
let firstYearPrices = rawFirstPrices.map(v => v.textContent).filter(containsDigit)
 
/// а теперь по-нормальному
let domainNames = $x("//div[@class='row searchResultRowTable']//small[@class='text-muted renewsAtContainer']/../../../div[contains(@class, 'availableDomain')]/text()").map(v => v.textContent)
let firstYearPrices = $x("//div[@class='row searchResultRowTable']//small[@class='text-muted renewsAtContainer']/../text()").map(v => v.textContent)
let renewPrices = $x("//div[@class='row searchResultRowTable']//small[@class='text-muted renewsAtContainer']/text()").map(v => v.textContent)
let parsed = []
for(let i = 0; i < domainNames.length; i++){
    let n = domainNames[i].match("[\\w\\.]+")[0];
    let fp = parseFloat(firstYearPrices[i].match("[\\d\\.]+") == null? NaN : firstYearPrices[i].match("[\\d\\.]+")[0]);
    let rp = parseFloat(renewPrices[i].match("[\\d\\.]+") == null? NaN : renewPrices[i].match("[\\d\\.]+"));
    parsed.push({name: n, firstPrice: fp, renewPrice: rp});
}
parsed.sort( (a,b) => {if(a.renewPrice < b.renewPrice){return -1;}else if(a.renewPrice == b.renewPrice){return 0;}else{return 1}} );
parsed.forEach((cur,i,arr) => {console.log(`name: ${cur.name} firstPrice: ${cur.firstPrice} renewPrice: ${cur.renewPrice}`)})
