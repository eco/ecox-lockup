import * as ethers from 'ethers'
import * as fs from 'fs'
require('dotenv').config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
// const TOKEN = process.env.TOKEN || ''
const POLICY = process.env.POLICY || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''

let ID_ECOX = ethers.utils.solidityKeccak256( ['string'],['ECOx'])
let ID_ECOX_STAKING = ethers.utils.solidityKeccak256( ['string'],['ECOxStaking'])

type lockupInfo = {
    beneficiary: string
    amounts: string[]
    timestamps: number[]
}

let lockupVaultABI = getABI('ECOxLockupVault')
let lockupFactoryABI = getABI('ECOxLockupVaultFactory')
let policyABI = getABI('Policy')
let ecoxStakingABI = getABI('ECOxStaking')
let ecoxABI = getABI('ECOx')
let lockupInfos: lockupInfo[] = []

function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function deployVaultFactory() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    let lockupVaultImpl = await implFactory.deploy()
    await lockupVaultImpl.deployTransaction.wait()
    console.log(`lockupVaultimpl: ${lockupVaultImpl.address}`)

    let policy = new ethers.Contract(POLICY, policyABI.abi, wallet)
    let ecoX = new ethers.Contract(await policy.policyFor(ID_ECOX), ecoxABI.abi, wallet)
    let ecoXStaking = new ethers.Contract(await policy.policyFor(ID_ECOX_STAKING), ecoxStakingABI.abi, wallet)

    let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    let lockupVaultFactory = await lockupVaultFactoryFactory.deploy(lockupVaultImpl, ecoX, ecoXStaking)
    await lockupVaultFactory.deployTransaction.wait()
    console.log(`lockupVaultFactory: ${lockupVaultImpl.address}`)
}

async function launchVaults(lockupVaultFactory: any, lockupCsvFilename: string) {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    // populates lockupInfos
    await processInputs(lockupCsvFilename)

    let tx
    let receipt
    for (let i = 0; i < lockupInfos.length; i++) {
        let info: lockupInfo = lockupInfos[i]
        try {
            console.log(`trying to deploy lockup for ${info.beneficiary}`)
            tx = await lockupVaultFactory.connect(wallet).createVault(info.beneficiary, ADMIN, info.amounts, info.timestamps)
            receipt = await tx.wait()
            if (receipt.status === 1) {
                console.log(`deployed lockup for ${info.beneficiary}`)
                await new Promise(r => setTimeout(r, 30000));
                continue
            }
        } catch (e) {
            console.log(`failed to deploy lockup for ${info.beneficiary}`)
        }
    }
    let events: any[] = await lockupVaultFactory.queryFilter('VaultCreated')

    for (let i = 0; i < events.length; i++) {
        let beneficiary = events[i].args.beneficiary
        let employeeVaultAddress = events[i].args.vault
        fs.writeFileSync('investorOutput.csv', '\n' + beneficiary + ',' + employeeVaultAddress, {
            encoding: 'utf8',
            flag: 'a+'
        })
    }
}

async function processInputs(filename: string) {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)

    let investorData = (fs.readFileSync(filename, 'utf8')).split('\r\n,,\r\n')
    let startTime: number = (await provider.getBlock('latest')).timestamp
    for (let i = 0; i < investorData.length; i++) {
        try {
            let amounts: string[] = []
            let timestamps: number[] = []
            let entry = investorData[i].split(',,\r')
            let beneficiary = entry[0]
            let pairs = entry[1]
            pairs.split('\r\n').forEach( function (pair) {
                let pieces = pair.split(',')
                amounts.push(pieces[1])
                //convert delta timestamps into actual timestamps
                timestamps.push(parseInt(pieces[2]) + startTime)
            })
            // console.log(beneficiary, amounts, timestamps)
            lockupInfos.push({beneficiary, amounts, timestamps})
        } catch (e) {
            console.log(investorData[i])
        }
        console.log(lockupInfos[1])
    }
}

// async function testInitialize(vaultAddressA32: string) {
//     let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
//     let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
//     let ecoxStaking = new ethers.Contract(ecoxStakingAddress, ecoxStakingABI.abi)
//     await ecoxStaking.connect(wallet).enableDelegationTo()
//     let vault = new ethers.Contract(vaultAddressA32, lockupVaultABI.abi, wallet)
//     await vault.delegate(await wallet.getAddress())
// }

// async function checkClaiming(vaultAddressA32: string) {
//     let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
//     let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
//     let ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)
//     let initialbal = await ecox.balanceOf(await wallet.getAddress())
//     console.log(initialbal.toString())
//     let vault = new ethers.Contract(vaultAddressA32, lockupVaultABI.abi, wallet)
//     let vaultbal = await ecox.balanceOf(vaultAddressA32)
//     console.log(vaultbal.toString())
//     let tx = await vault.claim()
//     tx = await tx.wait()
//     console.log(tx.status)
//     await new Promise(r => setTimeout(r, 20000));
//     vaultbal = await ecox.balanceOf(vaultAddressA32)
//     console.log(vaultbal.toString())
// }

// async function stake() {
//     let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
//     let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
//     let ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)
//     let vaultAddress = '0xEE5d1cd1b665CBB8ddA6EA1445433B2F4F166e87'

//     let vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
//     console.log(await vault.lockup())
//     console.log(await vault.beneficiary())
//     console.log(await wallet.getAddress())
//     let stakedAmount = '100000000000000000000'
//     // let tx = await ecox.approve('0x96fa9c18d6A6F6c321Ab396555E4Db8C976217eA', stakedAmount)
//     // tx = await tx.wait()
//     // console.log(tx.status)

//     let tx = await vault.stake(stakedAmount)
//     tx = await tx.wait()
//     console.log(tx.status)
// }


async function checkBeneficiary() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let vaultAddress = '0xF2227f0c27929139Ace55E45569FAE2f963d6A44'

    let vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
    console.log(await vault.beneficiary())
}

// checkBeneficiary().catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
// test('0xF2e05c7687D78D11D8667130bD2d128C4854A874').catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
// checkClaiming('0xEE5d1cd1b665CBB8ddA6EA1445433B2F4F166e87').catch((error) => {
//     console.error(error)
//     process.exitCode = 1
// })
fetchInvestorInfo('input/investors2.csv')