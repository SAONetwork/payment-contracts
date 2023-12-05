
const dataId= args[0]

const metadata = Functions.makeHttpRequest({
    url : `https://api-beta.sao.network/SaoNetwork/sao/model/metadata/${dataId}`,
})

const [metadataResp] = await Promise.all([metadata])

let status = 0;

if (metadataResp.data) {
    status = metadataResp.data.metadata.status
}

return Functions.encodeUint256(status)
