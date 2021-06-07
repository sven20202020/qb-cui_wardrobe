fx_version 'cerulean'
game 'gta5'

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/script.js',
    'ui/style.css',
    'ui/assets/fonts/signpainter.woff2',
    '@qb-cui_character/ui/assets/fonts/chaletlondon1960.woff2',
    'ui/assets/icons/accept.svg',
    'ui/assets/icons/cancel.svg',
    'ui/assets/icons/clear.svg',
    'ui/assets/icons/save.svg',
}

dependencies {
    'qb-cui_character'
}