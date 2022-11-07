// https://porkbun.com
// in developer console out all prices for domain search sorted by renew price ascending

var priceNodes = $x("//div[@class='row searchResultRowTable']//small[@class='text-muted renewsAtContainer']/../../../div[contains(@class, 'availableDomain')]/..")
var parsed = []
priceNodes.forEach((node, a, b) => {
    let rawName = node.getElementsByClassName("availableDomain")[0].textContent
    let renewPrice = node.getElementsByClassName("renewsAtContainer")[0].textContent
    let rawCurrentPrice = node.querySelector("span.childContent").innerText.replaceAll('\n','')
    let m = rawCurrentPrice.match("(?<strikedPrice>\\$[\\d\\.]+)?\\s?(?<currentPrice>\\$[\\d\\.]+)")
    let currentPrice = m.groups['currentPrice']
    //console.log(`rawName: ${rawName} rawRenewPrice: ${renewPrice} rawCurrentPrice: ${currentPrice}`)
    let n = rawName.match("[\\w\\.]+")[0];
    m = currentPrice.match("[\\d\\.]+")
    let fp = parseFloat( null == m? NaN : m[0])
    m = renewPrice.match("[\\d\\.]+")
    let rp = parseFloat(null == m? NaN : m[0])
    parsed.push({name: n, firstPrice: fp, renewPrice: rp});
})
parsed.sort( (a,b) => {if(a.renewPrice < b.renewPrice){return -1;}else if(a.renewPrice == b.renewPrice){return 0;}else{return 1}} );
parsed.forEach((cur,i,arr) => {console.log(`name: ${cur.name} firstPrice: ${cur.firstPrice} renewPrice: ${cur.renewPrice}`)})
