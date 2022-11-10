import * as ethers from 'ethers'
import * as fs from 'fs'
require('dotenv').config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
const TOKEN = process.env.TOKEN || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''
const ecoxStakingAddress = '0x72ba9863cb4f42010695cb62c52e363b5fe0d436'

let lockupVaultABI = getABI('ECOxEmployeeLockup')
let lockupFactoryABI = getABI('ECOxEmployeeLockupFactory')

let ecoxStakingABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/governance/community/ECOxStaking.sol/ECOxStaking.json', 'utf8'))
let ecoXABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/currency/ECOx.sol/ECOx.json', 'utf8'))

function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function main() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let otherWallet: ethers.Wallet = new ethers.Wallet('0594bfd43a475db159a261a7222774d0f269498588cce7d3bae2aa52817c7cb4', provider)
    
    let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    let lockupImpl = await implFactory.deploy()
    let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    let lockupVaultFactory = await lockupVaultFactoryFactory.deploy(lockupImpl.address, TOKEN)
    // let lockupVaultFactory = new ethers.Contract('0xe1D86fE06faD281ac5765B55456a16DB08941624', lockupFactoryABI.abi, wallet)
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)

    // let ecoxStaking = new ethers.Contract(ecoxStakingAddress, ecoxStakingABI.abi)
    // await ecoxStaking.connect(wallet).enableDelegationTo()
    // await ecoxStaking.connect(otherWallet).enableDelegationTo()
    
    let cliffTimestamp = (await provider.getBlock('latest')).timestamp + parseInt(LOCKUP_DURATION)
    let employeeBeneficiaryAddresses = (fs.readFileSync('employeeAddresses.csv', 'utf8')).split(',')
    // let tx
    // let receipt 
    for (let i = 0; i < employeeBeneficiaryAddresses.length; i++) {
        try {
            let beneficiary = employeeBeneficiaryAddresses[i]
            console.log(`deploying lockup for ${beneficiary}`)
            // tx = await lockupVaultFactory.connect(wallet).createVault(beneficiary, ADMIN, cliffTimestamp)
            // receipt = await tx.wait()
            let tx = await lockupVaultFactory.connect(wallet).createVault(beneficiary, ADMIN, cliffTimestamp)
            let receipt = await tx.wait()
            if (receipt.status === 1) {
                console.log(`deployed lockup for ${beneficiary}`)
                await new Promise(r => setTimeout(r, 20000));
                continue
            }
        } catch (e) {
            console.log(e)
            // console.log(tx)
            // console.log(receipt)
        }
    }
    let events: any[] = await lockupVaultFactory.queryFilter('VaultCreated')

    for (let i = 0; i < events.length; i++) {
        let beneficiary = events[i].args.beneficiary
        let employeeVaultAddress = events[i].args.vault
        fs.writeFileSync('employeeOutput.csv', '\n' + beneficiary + ',' + employeeVaultAddress, {
            encoding: 'utf8',
            flag: 'a+'
        })
    }
}

async function testInitialize(vaultAddressA32: string) {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let ecoxStaking = new ethers.Contract(ecoxStakingAddress, ecoxStakingABI.abi)
    await ecoxStaking.connect(wallet).enableDelegationTo()
    let vault = new ethers.Contract(vaultAddressA32, lockupVaultABI.abi, wallet)
    await vault.delegate(await wallet.getAddress())
}

async function checkClaiming(vaultAddressA32: string) {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)
    let initialbal = await ecox.balanceOf(await wallet.getAddress())
    console.log(initialbal.toString())
    let vault = new ethers.Contract(vaultAddressA32, lockupVaultABI.abi, wallet)
    let vaultbal = await ecox.balanceOf(vaultAddressA32)
    console.log(vaultbal.toString())
    let tx = await vault.claim()
    tx = await tx.wait()
    console.log(tx.status)
    await new Promise(r => setTimeout(r, 20000));
    vaultbal = await ecox.balanceOf(wallet.getAddress())
    console.log(vaultbal.toString())
}

// main().catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
// test('0xF2e05c7687D78D11D8667130bD2d128C4854A874').catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
checkClaiming('0xcad1568EF48D3269639b70745D20A1821f9afE11').catch((error) => {
    console.error(error)
    process.exitCode = 1
})