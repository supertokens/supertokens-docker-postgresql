const https = require("https")
const fs = require("fs")

const README = fs.readFileSync("./README.md", {encoding: "utf-8"});
const data = JSON.stringify({
    full_description: README,
    description: "Docker image for SuperTokens with PostgreSQL"
});
const token = process.env.TOKEN;
const options = {
    hostname: "hub.docker.com",
    port: 443,
    path: "/v2/repositories/supertokens/supertokens-postgresql/",
    method: "PATCH",
    headers: {
        "Content-Type": "application/json",
        "Content-Length": data.length,
        "Authorization": `JWT ${token}`
    }
}


const req = https.request(options, res => {
    console.log(`statusCode: ${res.statusCode}`);

    res.on('data', d => {
        process.stdout.write(d);
    });
})

req.on('error', error => {
    console.error(error)
});

req.write(data);
req.end();