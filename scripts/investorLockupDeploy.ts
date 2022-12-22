import * as ethers from 'ethers'
import * as fs from 'fs'
require('dotenv').config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
const TOKEN = process.env.TOKEN || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''

let lockupVaultABI = getABI('ECOxLockupVault')
let lockupFactoryABI = getABI('ECOxLockupVaultFactory')

let ecoxStakingABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/governance/community/ECOxStaking.sol/ECOxStaking.json', 'utf8'))
let ecoXABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/currency/ECOx.sol/ECOx.json', 'utf8'))

function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function deployVaultFactory() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
}

async function main() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    // let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    // let lockupImpl = await implFactory.deploy()
    // await lockupImpl.deployTransaction.wait()
    // console.log(lockupImpl.address)

    let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    let lockupVaultFactory = await lockupVaultFactoryFactory.deploy('0x6dBe4F2A157B6A6802c2C62F465DB5d1a52Fd019', TOKEN, '0x3a16f2Fee32827a9E476d0c87E454aB7C75C92D7')
    // let lockupVaultFactory = new ethers.Contract('0xe1D86fE06faD281ac5765B55456a16DB08941624', lockupFactoryABI.abi, wallet)
    await lockupVaultFactory.deployTransaction.wait()
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)

    // let ecoxStaking = new ethers.Contract(ecoxStakingAddress, ecoxStakingABI.abi)
    // await ecoxStaking.connect(wallet).enableDelegationTo()
    // await ecoxStaking.connect(otherWallet).enableDelegationTo()
    
    let cliffTimestamp = (await provider.getBlock('latest')).timestamp + parseInt(LOCKUP_DURATION)
    let employeeBeneficiaryAddresses = (fs.readFileSync('inputs2.csv', 'utf8')).split(',')
    // let tx
    // let receipt 
    console.log(employeeBeneficiaryAddresses.length)
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
                await new Promise(r => setTimeout(r, 30000));
                continue
            }
        } catch (e) {
            // console.log(e)
            console.log(employeeBeneficiaryAddresses[i])
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

async function fetchInvestorInfo() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    let lockupImpl = await implFactory.deploy()
    await lockupImpl.deployTransaction.wait()
    console.log(lockupImpl.address)

    let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    let lockupVaultFactory = await lockupVaultFactoryFactory.deploy('0x6dBe4F2A157B6A6802c2C62F465DB5d1a52Fd019', TOKEN, '0x3a16f2Fee32827a9E476d0c87E454aB7C75C92D7')
    // let lockupVaultFactory = new ethers.Contract('0xe1D86fE06faD281ac5765B55456a16DB08941624', lockupFactoryABI.abi, wallet)
    await lockupVaultFactory.deployTransaction.wait()
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)

    let investorData = (fs.readFileSync('input/investors1.csv', 'utf8')).split('\r\n,,\r\n,,')
    console.log(investorData.length)
    for (let i = 0; i < investorData.length; i++) {
        try {
            let amounts: string[] = []
            let timestamps: string[] = []
            let entry = investorData[i].split(',,\r')
            let beneficiary = entry[0]
            let pairs = entry[1]
            pairs.split('\r\n').forEach( function (pair) {
                let pieces = pair.split(',')
                amounts.push(pieces[1])
                timestamps.push(pieces[2])
            })
            // console.log(beneficiary, timestamps, amounts)
            console.log(`deploying lockup for ${beneficiary}`)

            let tx = await lockupVaultFactory.connect(wallet).createVault(beneficiary, ADMIN, amounts, timestamps)
            let receipt = await tx.wait()
            if (receipt.status === 1) {
                console.log(`deployed lockup for ${beneficiary}`)
                await new Promise(r => setTimeout(r, 30000));
                continue
            }
            
        } catch (e) {
            // console.log(e)
            console.log(investorData[i])
            // console.log(tx)
            // console.log(receipt)
        }

        let events: any[] = await lockupVaultFactory.queryFilter('VaultCreated')

        for (let i = 0; i < events.length; i++) {
            let beneficiary = events[i].args.beneficiary
            let employeeVaultAddress = events[i].args.vault
            fs.writeFileSync('output/investorOutput.csv', '\n' + beneficiary + ',' + employeeVaultAddress, {
                encoding: 'utf8',
                flag: 'a+'
            })
        }
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
fetchInvestorInfo()