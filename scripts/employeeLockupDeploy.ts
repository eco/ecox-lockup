import * as hardhat from "hardhat"
import * as ethers from 'ethers'
import * as fs from 'fs'
import * as path from 'path';
require('dotenv').config({ path: '.env' })

const RPCURL = process.env.RPCURL || ''
const signerPK = process.env.PK || ''
const TOKEN = process.env.TOKEN || ''
const LOCKUP_DURATION = process.env.DURATION || ''
const ADMIN = process.env.ADMIN || ''
const ecoxStakingAddress = '0x72ba9863cb4f42010695cb62c52e363b5fe0d436'

let lockupABI = getABI('ECOxEmployeeLockup')
let lockupFactoryABI = getABI('ECOxEmployeeLockupFactory')
let ecoxStakingABI = JSON.parse(fs.readFileSync('../currency/artifacts/contracts/governance/community/ECOxStaking.sol/ECOxStaking.json', 'utf8'))

function getABI(filename: string) {
    return JSON.parse(fs.readFileSync(`out/${filename}.sol/${filename}.json`, 'utf8'))
}

async function main() {
    let provider: ethers.providers.BaseProvider = new ethers.providers.JsonRpcProvider(RPCURL)
    let wallet: ethers.Wallet = new ethers.Wallet(signerPK, provider)
    let otherWallet: ethers.Wallet = new ethers.Wallet('0594bfd43a475db159a261a7222774d0f269498588cce7d3bae2aa52817c7cb4', provider)
    
    let implFactory = new ethers.ContractFactory(lockupABI.abi, lockupABI.bytecode, wallet)
    let lockupImpl = await implFactory.deploy()
    let lockupVaultFactoryFactory = new ethers.ContractFactory(lockupFactoryABI.abi, lockupFactoryABI.bytecode, wallet)
    let lockupVaultFactory = await lockupVaultFactoryFactory.deploy(lockupImpl.address, TOKEN)
    console.log(`lockup vault factory: ${lockupVaultFactory.address}`)

    let ecoxStaking = new ethers.Contract(ecoxStakingAddress, ecoxStakingABI.abi)
    await ecoxStaking.connect(wallet).enableDelegationTo()
    await ecoxStaking.connect(otherWallet).enableDelegationTo()
    
    let cliffTimestamp = (await provider.getBlock('latest')).timestamp + parseInt(LOCKUP_DURATION)
    let employeeBeneficiaryAddresses = (fs.readFileSync('employeeAddresses.csv', 'utf8')).split(',')
    for (let i = 0; i < employeeBeneficiaryAddresses.length; i++) {
        try {
            let beneficiary = employeeBeneficiaryAddresses[i]
            console.log(`deploying lockup for ${beneficiary}`)
            let tx = await lockupVaultFactory.connect(wallet).createVault(beneficiary, ADMIN, cliffTimestamp)
            let receipt = await tx.wait()
            if (receipt.status === 1) {
                console.log(`deployed lockup for ${beneficiary}`)
                continue
            }
        } catch (e) {
            console.log(e)
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

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})