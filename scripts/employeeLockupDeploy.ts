import * as ethers from 'ethers'
import * as fs from 'fs'
require('dotenv').config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
const TOKEN = process.env.TOKEN || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''

let lockupVaultABI = getABI('ECOxEmployeeLockup')
let lockupFactoryABI = getABI('ECOxEmployeeLockupFactory')

let ecoxStakingABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/governance/community/ECOxStaking.sol/ECOxStaking.json', 'utf8'))
let ecoXABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/currency/ECOx.sol/ECOx.json', 'utf8'))

let inputFile = "inputs2.csv"
let outputFile = "employeeOutput.csv"
let lockupImpl = '0x6dBe4F2A157B6A6802c2C62F465DB5d1a52Fd019'
let stakingImpl = '0x3a16f2Fee32827a9E476d0c87E454aB7C75C92D7'
let factoryAddress = '0x61aF871A420a36859df228b66411992190DDeCDF'


function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function main() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    // create new impl: 

    // let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    // let lockupImpl = await implFactory.deploy()
    // await lockupImpl.deployTransaction.wait()
    // console.log(lockupImpl.address)

    // create new factory: 

    // let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    // let lockupVaultFactory = await lockupVaultFactoryFactory.deploy(lockupImpl, TOKEN, stakingImpl)

    let lockupVaultFactory = new ethers.Contract(factoryAddress, lockupFactoryABI.abi, wallet)
    await lockupVaultFactory.deployTransaction.wait()
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)
    
    let cliffTimestamp = (await provider.getBlock('latest')).timestamp + parseInt(LOCKUP_DURATION)
    let employeeBeneficiaryAddresses = (fs.readFileSync(inputFile, 'utf8')).split(',')
    let tx
    let receipt 
    console.log(employeeBeneficiaryAddresses.length)
    for (let i = 0; i < employeeBeneficiaryAddresses.length; i++) {
        try {
            let beneficiary = employeeBeneficiaryAddresses[i]
            console.log(`deploying lockup for ${beneficiary}`)
            tx = await lockupVaultFactory.connect(wallet).createVault(beneficiary, ADMIN, cliffTimestamp)
            receipt = await tx.wait()
            if (receipt.status === 1) {
                console.log(`deployed lockup for ${beneficiary}`)
                // wait until tx goes through, doesn't work without this
                await new Promise(r => setTimeout(r, 30000));
                continue
            }
        } catch (e) {
            console.log(employeeBeneficiaryAddresses[i])
        }
    }
    let events: any[] = await lockupVaultFactory.queryFilter('VaultCreated')

    for (let i = 0; i < events.length; i++) {
        let beneficiary = events[i].args.beneficiary
        let employeeVaultAddress = events[i].args.vault
        fs.writeFileSync(outputFile, '\n' + beneficiary + ',' + employeeVaultAddress, {
            encoding: 'utf8',
            flag: 'a+'
        })
    }
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
    vaultbal = await ecox.balanceOf(vaultAddressA32)
    console.log(vaultbal.toString())
}

async function stake() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)
    let vaultAddress = '0xEE5d1cd1b665CBB8ddA6EA1445433B2F4F166e87'

    let vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
    console.log(await vault.lockup())
    console.log(await vault.beneficiary())
    console.log(await wallet.getAddress())
    let stakedAmount = '100000000000000000000'
    // let tx = await ecox.approve('0x96fa9c18d6A6F6c321Ab396555E4Db8C976217eA', stakedAmount)
    // tx = await tx.wait()
    // console.log(tx.status)

    let tx = await vault.stake(stakedAmount)
    tx = await tx.wait()
    console.log(tx.status)
}

async function checkBeneficiary(vaultAddress: string) {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    let vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
    console.log(await vault.beneficiary())
}