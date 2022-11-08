import * as hardhat from "hardhat"
import * as fs from 'fs'
import * as path from 'path';

async function main() {
    fs.readFile('testDeploy.json', "utf8", function(err, data) {
        let allData = JSON.parse(data)
        let universals = allData.data
        let employeeData = allData.employees
        console.log(employeeData)
        console.log(universals)
    })


    
    // let employeeData: any[] = []

    // for (let i: number = 0; i < employeeData.length; i++) {

    // }

}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})