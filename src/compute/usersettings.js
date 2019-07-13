let database = require("./database")
let usersettings = {}

let Settings

usersettings.load = async () => {
    Stats = await database.getAllSettings()
}

module.exports = userstats