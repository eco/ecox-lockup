import * as ethers from 'ethers'
import * as fs from 'fs'
import * as dotenv from 'dotenv'
dotenv.config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
const TOKEN = process.env.TOKEN || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''

const lockupVaultABI = getABI('ECOxCliffLockup')
const lockupFactoryABI = getABI('ECOxCliffLockupFactory')

const ecoxStakingABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/governance/community/ECOxStaking.sol/ECOxStaking.json', 'utf8'))
const ecoXABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/currency/ECOx.sol/ECOx.json', 'utf8'))

const inputFile = "inputs2.csv"
const outputFile = "cliffLockupOutput.csv"
const lockupImpl = '0x6dBe4F2A157B6A6802c2C62F465DB5d1a52Fd019'
const stakingImpl = '0x3a16f2Fee32827a9E476d0c87E454aB7C75C92D7'
const factoryAddress = '0x61aF871A420a36859df228b66411992190DDeCDF'

function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function main() {
    const provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    const wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    // create new impl: 

    // let implFactory = new ethers.ContractFactory(lockupVaultABI.abi, lockupVaultABI.bytecode, wallet)
    // let lockupImpl = await implFactory.deploy()
    // await lockupImpl.deployTransaction.wait()
    // console.log(lockupImpl.address)

    // create new factory: 

    // let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    // let lockupVaultFactory = await lockupVaultFactoryFactory.deploy(lockupImpl, TOKEN, stakingImpl)

    const lockupVaultFactory = new ethers.Contract(factoryAddress, lockupFactoryABI.abi, wallet)
    await lockupVaultFactory.deployTransaction.wait()
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)
    
    const cliffTimestamp = (await provider.getBlock('latest')).timestamp + parseInt(LOCKUP_DURATION)
    const beneficiaryAddresses = (fs.readFileSync(inputFile, 'utf8')).split(',')
    let tx
    let receipt 
    console.log(beneficiaryAddresses.length)
    for (let i = 0; i < beneficiaryAddresses.length; i++) {
        try {
            const beneficiary = beneficiaryAddresses[i]
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
            console.log(beneficiaryAddresses[i])
        }
    }
    const events: any[] = await lockupVaultFactory.queryFilter('VaultCreated')

    for (let i = 0; i < events.length; i++) {
        const beneficiary = events[i].args.beneficiary
        const beneficiaryVaultAddress = events[i].args.vault
        fs.writeFileSync(outputFile, '\n' + beneficiary + ',' + beneficiaryVaultAddress, {
            encoding: 'utf8',
            flag: 'a+'
        })
    }
}

async function checkClaiming(vaultAddressA32: string) {
    const provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    const wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    const ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)
    const initialbal = await ecox.balanceOf(await wallet.getAddress())
    console.log(initialbal.toString())
    const vault = new ethers.Contract(vaultAddressA32, lockupVaultABI.abi, wallet)
    let vaultbal = await ecox.balanceOf(vaultAddressA32)
    console.log(vaultbal.toString())
    let tx = await vault.claim()
    tx = await tx.wait()
    console.log(tx.status)
    await new Promise(r => setTimeout(r, 20000));
    vaultbal = await ecox.balanceOf(vaultAddressA32)
    console.log(vaultbal.toString())
}

async function stake(vaultAddress: string) {
    const provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    const wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    const ecox = new ethers.Contract(TOKEN, ecoXABI.abi, wallet)

    const vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
    console.log(await vault.lockup())
    console.log(await vault.beneficiary())
    console.log(await wallet.getAddress())
    const stakedAmount = '100000000000000000000'
    
    let tx = await ecox.approve('0x96fa9c18d6A6F6c321Ab396555E4Db8C976217eA', stakedAmount)
    tx = await tx.wait()
    console.log(tx.status)

    tx = await vault.stake(stakedAmount)
    tx = await tx.wait()
    console.log(tx.status)
}

async function checkBeneficiary(vaultAddress: string) {
    const provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    const wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)

    const vault = new ethers.Contract(vaultAddress, lockupVaultABI.abi, wallet)
    console.log(await vault.beneficiary())
}
