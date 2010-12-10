-- Hardek's neobot library 0.9.4
print('Hardek Library Version: 0.9.4')

function waitping(base)
    local base = base or 200
    if ping == 0 then ping = base end
    wait(2 * ping, 4 * ping)
end

function timeleft(t)
    return tosec(t) - tosec(currenttime())
end

function depositall()
    npctalk('hi', 'deposit all', 'yes')
end

function withdraw(amount, npc, sayhi)
    if not amount or amount == 0 then
        return true
    end

    if sayhi == true then
        npctalk('hi', 'withdraw ' .. amount, 'yes')
    else
        npctalk('withdraw ' .. amount, 'yes')
    end

    waitping()
    foreach newmessage m do
        if m.content == 'There is not enough gold on your account.' then
            if (not npc) or (npc == '') or (m.sender == npc) then
                return false
            end
        end
    end

    return true
end

function tryexec(cmd, x, y, z, maxtries)
    local tries = 0
    maxtries = maxtries or 5
    
    while tries <= maxtries do
        if $posx ~= x or $posy ~= y or $posz ~= z then
            moveto(x, y, z)
            tries = tries + 1
            waitping()
        else
            exec(cmd)
            return true
        end
    end

    return false
end

function opendepot()
    local wtp = getsetting('Cavebot/Pathfinding/WalkThroughPlayers') 
    if wtp == 'yes' then setsetting('Cavebot/Pathfinding/WalkThroughPlayers', 'no') end

    reachgrounditem('depot') waitping()
    openitem('depot') waitping()
    
    setsetting('Cavebot/Pathfinding/WalkThroughPlayers', wtp)
end

function movetoinsist(x, y, z, maxtries)
    local tries = 0
    maxtries = maxtries or 5

    while tries <= maxtries and $posx ~= x and $posy ~= y do
        tries = tries + 1
        if $posz ~= z then return false end
        moveto(x, y, z)
        waitping()
    end

    return true
end

function refillsofts()
    local quit = false
    npctalk('hi')
    while not quit and itemcount('worn soft boots') > 0 do
        npctalk('repair', 'yes')
        wait(2000, 3000)
        foreach newmessage m do
            if m.content == 'At last, someone poorer than me.' then
                if (not npc) or (m.sender == 'Aldo') then
                    if not (movetoinsist(33019, 32053, 6) and 
                        withdraw(10000, 'Rokyn', true) and
                        movetoinsist(32953, 32108, 6)) then
                        quit = true
                    else
                        npcsay('hi')
                    end
                end
            end
        end
    end
end

function __loop_open(container, ignore, maxtries)
    if type(container) == 'string' then container = container:lower() end
    ignore = ignore:lower()
    maxtries = maxtries or 5
    if container == ignore then return (windowcount(container) ~= 0) end

    local countbefore = windowcount()
    local tries = 0
    while (countbefore == windowcount()) and windowcount(container) == 0 and tries <= maxtries do
        if tries == maxtries then return false end
        openitem(container, 'Locker', true)
        waitping()
        tries = tries + 1
    end

    return true
end

function __dp_item(item, from, container, container_id)
    local continue = true

    while continue and itemcount(item, from) > 0 do
        if emptycount(container_id) == 0 then
            continue = (itemcount(container) > 0)
            if continue then
                openitem(container, container_id)
                waitping()
            end
        else
            moveitems(item, container_id, from)
            waitping()
        end
    end
end

function deposititems(dest, stack, from, open, ...)
    local items = {...}
    if type(items[1]) == 'table' then items = items[1] end
    if open and windowcount('locker') == 0 then opendepot() waitping() end
    dest = dest or 'locker'
    stack = stack or 'locker'
    if type(from) ~= 'table' then from = {from} end
    if type(dest) == 'string' then dest = dest:lower() end
    if type(stack) == 'string' then stack = stack:lower() end

    if (not __loop_open(stack, 'locker')) or (not __loop_open(dest, 'locker')) then return false end

    destd = windowcount() - 1
    if stack == dest then stackd = destd else stackd = destd - 1 end

    for i = 1, #items do
        if itemproperty(items[i], ITEM_STACKABLE) then
            for j = 1, #from do
                __dp_item(items[i], from[j], stack, stackd)
            end
        end
    end

    for i = 1, #items do
        if not itemproperty(items[i], ITEM_STACKABLE) then
            for j = 1, #from do
                __dp_item(items[i], from[j], dest, destd)
            end
        end
    end
end

function dropitemsex(cap, ...)
    local cap = cap or 250
    local drop = {...}

    if $cap < cap then
        for i = 1, #drop do
            while $cap < cap and itemcount(drop[i]) > 0 do
                local count = math.ceil((cap - $cap) / itemweight(drop[i]))
                moveitems(itemid(drop[i]), 'ground', '', count)
            end
        end
    end
end

function dontlist()
    listas('dontlist')
end

function goback()
    gotolabel(0)
end

function creatureinfo(creaturename)
    if creaturename == '' then return nil end
    return creatures_table[table.binaryfind(creatures_table,creaturename:lower(),'name')]
end

function creaturemaxhp(creaturename)
    if creaturename == '' then return 0 end
    local cre = creatureinfo(creaturename)
    if cre then return cre.hp end
	printerror('Monster: '..creaturename..' not found')
    return 0
end

function creaturehp(creaturename)
    if creaturename == '' then return 0 end
    if type(creaturename) ~= 'userdata' then
        creaturename = findcreature(creaturename)
    end
    local cre = creaturename
    local creinfo = creatureinfo(creaturename)
    if not creinfo then
        printerror('Monster: '..creaturename..' not found')
        return 0
    end
    return cre.hp*100/creinfo.hp
end

function creatureexp(creaturename)
    if creaturename == '' then return 0 end
    local cre = creatureinfo(creaturename)
    if cre then return cre.exp end
	printerror('Monster: '..creaturename..' not found')
    return 0
end

function expratio(creaturename)
    if creaturename == '' then return 0 end
    local cre = creatureinfo(creaturename)
    if cre then return cre.ratio end
	printerror('Monster: '..creaturename..' not found')
    return 0
end

function maxdamage(creaturename)
    if creaturename == '' then return 0 end
    if creaturename then
        local cre = creatureinfo(creaturename)
        if cre then return cre.maxdmg end
		printerror('Monster: '..creaturename..' not found')
        return 0
    else
        local total = 0
        foreach creature c "ms" do
            total = total + maxdamage(c.name)
        end
        return total
    end
end

function getelementword(element)
    local spells = {death = 'mort', fire = 'flam', ice = 'frigo', energy = 'vis', earth = 'tera'}
    if spells[element] then return spells[element] end
    printerror('Element: '..element..' not found')
    return nil
end

function bestelement(creaturename)
    if creaturename == '' then return nil end
    local cre = creatureinfo(creaturename)
    if cre then return cre.bestspell end
	printerror('Monster: '..creaturename..' not found')
    return nil
end

function bestspell(creaturename)
    if creaturename == '' then return nil end
    local cre = creatureinfo(creaturename)
    if cre then return 'exori '..getelementword(cre.bestspell) end
    printerror('Monster: '..creaturename..' not found')
    return nil
end

function buyitemstocap(itemname, cap)
    local tries = 0
    local amount = math.floor(($cap - cap) / itemweight(itemname))
    local maxtries = maxtries or (2 * amount / 100)

    if not $tradeopen then opentrade() end
    while $cap > cap and tries <= maxtries do
        count = itemcount(itemname)
        amount = math.floor(($cap - cap) / itemweight(itemname)) % 100
        if amount == 0 then amount = 100 end
        buyitems(itemname, amount)
        waitping()
        tries = tries + 1
    end
end

function itemscosttocap(itemname, cap)
    local item = iteminfo(itemname)
    if item then
        return item.npcprice * math.floor((($cap - cap) / item.weight))
    end
    printerror('Item: '..itemname..' not found')
    return 0
end

function trapped()
        for i = -2, 2 do
            for j = -2, 2 do
                local cx = $posx + i
                local cy = $posy + j
                if tilereachable(cx, cy, $posz) then return false end
            end
        end

    return true
end

function euclideandist(sx, sy, dx, dy)
    return math.sqrt(math.pow(dx - sx, 2) + math.pow(dy - sy, 2))
end

function distto(sx, sy, dx, dy)
    local distx = math.abs(sx - dx)
    local disty = math.abs(sy - dy)
    if distx > disty then
        return distx
    else
        return disty
    end    
end

function leavetrap(spell)
    spell = spell or 'none'
    local cr = nil
    local distmin = 100
    local sp = ''
    local cb = $cavebot

    if cb and trapped() then setcavebot('off') end
    while trapped() do
        wait(1000)
        foreach creature c "ms" do
            if c.dist == 1 then
                if cb then
                    if not cr then cr = c end
                    local dist = distto($wptx, $wpty, c.posx, c.posy)
                    if dist < distmin then
                        distmin = dist
                        cr = c
                    end
                else
                    cr = c
                    break
                end
            end
        end
        attack(cr)
        if spell ~= 'none' then
            if spell == 'strike' then sp = bestspell(cr.name) else sp = spell end
            cast(sp)
        end
    end
    if cb then setcavebot('on') end
end

function getplayerskill() -- credits for sirmate on this one
    local weaponType = findweapontype()
    local playerVocation = vocation()
    if (playerVocation == 'knight') then
        if (weaponType == 'club') then
            return {$club, $clubpc}
        elseif (weaponType == 'sword') then
            return {$sword, $swordpc}
        elseif (weaponType == 'axe') then
            return {$axe, $axepc}
        end
    elseif (playerVocation == 'paladin') then
        return {$distance, $distancepc}
    elseif (playerVocation == 'mage' or playerVocation == 'druid' or playerVocation == 'sorcerer') then
        if ($club >= $sword and $axe) then
            return {$club, $clubpc}
        elseif ($sword >= $club and $axe) then
            return {$sword, $swordpc}
        elseif ($axe >= $club and $sword) then
            return {$axe, $axepc}
        end
    end
end

function spelldamage(spell, level, mlevel, skill)
    level = level or $level
    mlevel = mlevel or $mlevel
    skill = skill or getplayerskill()[1]
    local sp = spell:gsub(' ', '_')
    if not spellformulas[sp] then
        printerror('Spell: '..spell..' not found.')
        return nil
    end
    return spellformulas[sp](level, mlevel, skill)
end


-- information tables

spellformulas = {
    beserk              = function(a, b, c) return {((a + b) * 0.5 + (c / 5)), ((a + b) * 1.5 + (c / 5))} end,
    whirlwind_throw     = function(a, b, c) return {(a + b) / 3 + c / 5, a + b + c / 5} end,
    fierce_beserk       = function(a, b, c) return {((a + b * 2) * 1.1 + (c / 5)), ((a + b * 2) * 3 + (c / 5))} end,
    etheral_spear       = function(a, b) return {(a + 25) / 3 + b / 5, (a + 25 + b / 5)} end,
    strike              = function(l, m) return {0.2 * l + 1.403 * m + 08, 0.2 * l + 2.203 * m + 13} end,
    divine_missile      = function(l, m) return {0.2 * l + 1.790 * m + 11, 0.2 * l + 3.000 * m + 18} end,
    ice_wave            = function(l, m) return {0.2 * l + 0.810 * m + 04, 0.2 * l + 2.000 * m + 12} end,
    fire_wave           = function(l, m) return {0.2 * l + 1.250 * m + 04, 0.2 * l + 2.000 * m + 12} end,
    light_magic_missile = function(l, m) return {0.2 * l + 0.400 * m + 02, 0.2 * l + 0.810 * m + 04} end,
    heavy_magic_missile = function(l, m) return {0.2 * l + 0.810 * m + 04, 0.2 * l + 1.590 * m + 10} end,
    stalagmite          = function(l, m) return {0.2 * l + 0.810 * m + 04, 0.2 * l + 1.590 * m + 10} end,
    icicle              = function(l, m) return {0.2 * l + 1.810 * m + 10, 0.2 * l + 3.000 * m + 18} end,
    fireball            = function(l, m) return {0.2 * l + 1.810 * m + 10, 0.2 * l + 3.000 * m + 18} end,
    holy_missile        = function(l, m) return {0.2 * l + 1.790 * m + 11, 0.2 * l + 3.750 * m + 24} end,
    sudden_death        = function(l, m) return {0.2 * l + 4.605 * m + 28, 0.2 * l + 7.395 * m + 46} end,
    thunderstorm        = function(l, m) return {0.2 * l + 1.000 * m + 06, 0.2 * l + 2.600 * m + 16} end,
    stone_shower        = function(l, m) return {0.2 * l + 1.000 * m + 06, 0.2 * l + 2.600 * m + 16} end,
    avalanche           = function(l, m) return {0.2 * l + 1.200 * m + 07, 0.2 * l + 2.800 * m + 17} end,
    great_fireball      = function(l, m) return {0.2 * l + 1.200 * m + 07, 0.2 * l + 2.800 * m + 17} end,
    explosion           = function(l, m) return {0.2 * l + 0.0 * m, 0.2 * l + 4.8 * m} end,
    energy_beam         = function(l, m) return {0.2 * l + 2.5 * m, 0.2 * l + 4.0 * m} end,
    great_energy_beam   = function(l, m) return {0.2 * l + 4.0 * m, 0.2 * l + 7.0 * m} end,
    divine_caldera      = function(l, m) return {0.2 * l + 4.0 * m, 0.2 * l + 6.0 * m} end,
    terra_wave          = function(l, m) return {0.2 * l + 3.5 * m, 0.2 * l + 7.0 * m} end,
    energy_wave         = function(l, m) return {0.2 * l + 4.5 * m, 0.2 * l + 9.0 * m} end,
    heal_friend         = function(l, m) return {0.2 * l + 010 * m, 0.2 * l + 014 * m} end,
    rage_of_the_skies   = function(l, m) return {0.2 * l + 5.0 * m, 0.2 * l + 012 * m} end,
    hells_core          = function(l, m) return {0.2 * l + 7.0 * m, 0.2 * l + 014 * m} end,
    wrath_of_nature     = function(l, m) return {0.2 * l + 5.0 * m, 0.2 * l + 010 * m} end,
    eternal_winter      = function(l, m) return {0.2 * l + 6.0 * m, 0.2 * l + 012 * m} end,
    divine_healing      = function(l, m) return {0.2 * l + 18.5 * m, 0.2 * l + 025 * m} end,
    light_healing       = function(l, m) return {0.2 * l + 1.400 * m + 08, 0.2 * l + 1.795 * m + 11} end,
    intense_healing     = function(l, m) return {0.2 * l + 3.184 * m + 20, 0.2 * l + 5.590 * m + 35} end,
    ultimate_healing    = function(l, m) return {0.2 * l + 7.220 * m + 44, 0.2 * l + 12.79 * m + 79} end,
    wound_cleansing     = function(l, m) return {0.2 * l + 4.000 * m + 25, 0.2 * l + 7.750 * m + 50} end,
    mass_healing        = function(l, m) return {0.2 * l + 5.700 * m + 26, 0.2 * l + 10.43 * m + 62} end,
}

creatures_table = {
    {name = "achad", exp = 70, hp = 185, ratio = 0.378, maxdmg = 80, bestspell = "death"},
    {name = "acid blob", exp = 250, hp = 250, ratio = 1.000, maxdmg = 160, bestspell = "fire"},
    {name = "acolyte of darkness", exp = 200, hp = 325, ratio = 0.615, maxdmg = 120, bestspell = "ice"},
    {name = "acolyte of the cult", exp = 300, hp = 390, ratio = 0.769, maxdmg = 220, bestspell = "energy"},
    {name = "adept of the cult", exp = 400, hp = 430, ratio = 0.930, maxdmg = 242, bestspell = "death"},
    {name = "amazon", exp = 60, hp = 110, ratio = 0.545, maxdmg = 60, bestspell = "death"},
    {name = "ancient scarab", exp = 720, hp = 1000, ratio = 0.720, maxdmg = 380, bestspell = "fire"},
    {name = "anmothra", exp = 10000, hp = 2100, ratio = 4.762, maxdmg = 350, bestspell = "death"},
    {name = "annihilon", exp = 15000, hp = 40000, ratio = 0.375, maxdmg = 2650, bestspell = "fire"},
    {name = "apocalypse", exp = 80000, hp = 160000, ratio = 0.500, maxdmg = 9800, bestspell = "death"},
    {name = "apprentice sheng", exp = 150, hp = 95, ratio = 1.579, maxdmg = 80, bestspell = "death"},
    {name = "arachir the ancient one", exp = 1800, hp = 1600, ratio = 1.125, maxdmg = 480, bestspell = "fire"},
    {name = "arkhothep (creature)", exp = 0, hp = 1, ratio = 0.000, maxdmg = 5000, bestspell = "death"},
    {name = "armenius (creature)", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "arthei", exp = 4000, hp = 4200, ratio = 0.952, maxdmg = 1000, bestspell = "fire"},
    {name = "ashmunrah", exp = 3100, hp = 5000, ratio = 0.620, maxdmg = 2412, bestspell = "fire"},
    {name = "assassin", exp = 105, hp = 175, ratio = 0.600, maxdmg = 160, bestspell = "death"},
    {name = "avalanche (creature)", exp = 305, hp = 550, ratio = 0.555, maxdmg = 250, bestspell = "energy"},
    {name = "axeitus headbanger", exp = 140, hp = 365, ratio = 0.384, maxdmg = 130, bestspell = "fire"},
    {name = "azerus", exp = 6000, hp = 7500, ratio = 0.800, maxdmg = 1000, bestspell = "death"},
    {name = "azure frog", exp = 20, hp = 60, ratio = 0.333, maxdmg = 24, bestspell = "fire"},
    {name = "badger", exp = 5, hp = 23, ratio = 0.217, maxdmg = 12, bestspell = "death"},
    {name = "bandit", exp = 65, hp = 245, ratio = 0.265, maxdmg = 43, bestspell = "death"},
    {name = "bane of light", exp = 450, hp = 925, ratio = 0.486, maxdmg = 0, bestspell = "energy"},
    {name = "banshee", exp = 900, hp = 1000, ratio = 0.900, maxdmg = 652, bestspell = "energy"},
    {name = "barbaria", exp = 355, hp = 345, ratio = 1.029, maxdmg = 170, bestspell = "death"},
    {name = "barbarian bloodwalker", exp = 195, hp = 305, ratio = 0.639, maxdmg = 200, bestspell = "earth"},
    {name = "barbarian brutetamer", exp = 90, hp = 145, ratio = 0.621, maxdmg = 54, bestspell = "death"},
    {name = "barbarian headsplitter", exp = 85, hp = 100, ratio = 0.850, maxdmg = 110, bestspell = "earth"},
    {name = "barbarian skullhunter", exp = 85, hp = 135, ratio = 0.630, maxdmg = 65, bestspell = "earth"},
    {name = "baron brute", exp = 3000, hp = 5025, ratio = 0.597, maxdmg = 474, bestspell = "death"},
    {name = "bat", exp = 10, hp = 30, ratio = 0.333, maxdmg = 8, bestspell = "earth"},
    {name = "battlemaster zunzu", exp = 2500, hp = 5000, ratio = 0.500, maxdmg = 650, bestspell = "death"},
    {name = "bazir", exp = 0, hp = 1, ratio = 0.000, maxdmg = 4000, bestspell = "death"},
    {name = "bear", exp = 23, hp = 80, ratio = 0.287, maxdmg = 25, bestspell = "ice"},
    {name = "behemoth", exp = 2500, hp = 4000, ratio = 0.625, maxdmg = 635, bestspell = "ice"},
    {name = "berserker chicken", exp = 220, hp = 465, ratio = 0.473, maxdmg = 270, bestspell = "death"},
    {name = "betrayed wraith", exp = 3500, hp = 4200, ratio = 0.833, maxdmg = 455, bestspell = "ice"},
    {name = "big boss trolliver", exp = 105, hp = 150, ratio = 0.700, maxdmg = 40, bestspell = "death"},
    {name = "black knight", exp = 1600, hp = 1800, ratio = 0.889, maxdmg = 500, bestspell = "death"},
    {name = "black sheep", exp = 0, hp = 20, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "blazing fire elemental", exp = 450, hp = 650, ratio = 0.692, maxdmg = 450, bestspell = "ice"},
    {name = "blightwalker", exp = 5850, hp = 8900, ratio = 0.657, maxdmg = 900, bestspell = "energy"},
    {name = "blistering fire elemental", exp = 1300, hp = 1500, ratio = 0.867, maxdmg = 975, bestspell = "ice"},
    {name = "blood crab", exp = 160, hp = 290, ratio = 0.552, maxdmg = 110, bestspell = "fire"},
    {name = "blood crab (underwater)", exp = 180, hp = 320, ratio = 0.562, maxdmg = 111, bestspell = "energy"},
    {name = "bloodpaw", exp = 50, hp = 100, ratio = 0.500, maxdmg = 40, bestspell = "energy"},
    {name = "bloom of doom", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "blue djinn", exp = 215, hp = 330, ratio = 0.652, maxdmg = 325, bestspell = "death"},
    {name = "bog raider", exp = 800, hp = 1300, ratio = 0.615, maxdmg = 600, bestspell = "energy"},
    {name = "bonebeast", exp = 580, hp = 515, ratio = 1.126, maxdmg = 340, bestspell = "fire"},
    {name = "bonelord", exp = 170, hp = 260, ratio = 0.654, maxdmg = 235, bestspell = "fire"},
    {name = "bones", exp = 3750, hp = 9500, ratio = 0.395, maxdmg = 1200, bestspell = "death"},
    {name = "boogey", exp = 475, hp = 930, ratio = 0.511, maxdmg = 200, bestspell = "fire"},
    {name = "boreth", exp = 1800, hp = 1400, ratio = 1.286, maxdmg = 800, bestspell = "fire"},
    {name = "bovinus", exp = 60, hp = 150, ratio = 0.400, maxdmg = 50, bestspell = "death"},
    {name = "braindeath", exp = 985, hp = 1225, ratio = 0.804, maxdmg = 700, bestspell = "fire"},
    {name = "bride of night", exp = 450, hp = 275, ratio = 1.636, maxdmg = 100, bestspell = "ice"},
    {name = "brimstone bug", exp = 900, hp = 1300, ratio = 0.692, maxdmg = 420, bestspell = "fire"},
    {name = "brutus bloodbeard", exp = 795, hp = 1200, ratio = 0.662, maxdmg = 350, bestspell = "energy"},
    {name = "bug", exp = 18, hp = 29, ratio = 0.621, maxdmg = 23, bestspell = "fire"},
    {name = "butterfly (blue)", exp = 0, hp = 2, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "butterfly (purple)", exp = 0, hp = 2, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "butterfly (red)", exp = 0, hp = 2, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "cake golem", exp = 0, hp = 1, ratio = 0.000, maxdmg = 120, bestspell = "death"},
    {name = "captain jones", exp = 825, hp = 800, ratio = 1.031, maxdmg = 400, bestspell = "death"},
    {name = "carniphila", exp = 150, hp = 255, ratio = 0.588, maxdmg = 330, bestspell = "fire"},
    {name = "carrion worm", exp = 70, hp = 145, ratio = 0.483, maxdmg = 45, bestspell = "fire"},
    {name = "cat", exp = 0, hp = 20, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "cave rat", exp = 10, hp = 30, ratio = 0.333, maxdmg = 10, bestspell = "fire"},
    {name = "centipede", exp = 34, hp = 70, ratio = 0.486, maxdmg = 46, bestspell = "fire"},
    {name = "chakoya toolshaper", exp = 40, hp = 80, ratio = 0.500, maxdmg = 80, bestspell = "energy"},
    {name = "chakoya tribewarden", exp = 40, hp = 68, ratio = 0.588, maxdmg = 30, bestspell = "energy"},
    {name = "chakoya windcaller", exp = 48, hp = 84, ratio = 0.571, maxdmg = 82, bestspell = "energy"},
    {name = "charged energy elemental", exp = 450, hp = 500, ratio = 0.900, maxdmg = 375, bestspell = "death"},
    {name = "chicken", exp = 0, hp = 15, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "chikhaton", exp = 35000, hp = 1, ratio = 35000.000, maxdmg = 1130, bestspell = "death"},
    {name = "chizzoron the distorter", exp = 0, hp = 8000, ratio = 0.000, maxdmg = 2300, bestspell = "fire"},
    {name = "cobra", exp = 30, hp = 65, ratio = 0.462, maxdmg = 5, bestspell = "fire"},
    {name = "cockroach", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "cocoon", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "coldheart", exp = 3500, hp = 7000, ratio = 0.500, maxdmg = 675, bestspell = "death"},
    {name = "colerian the barbarian", exp = 90, hp = 265, ratio = 0.340, maxdmg = 100, bestspell = "earth"},
    {name = "coral frog", exp = 20, hp = 60, ratio = 0.333, maxdmg = 24, bestspell = "fire"},
    {name = "countess sorrow", exp = 13000, hp = 6500, ratio = 2.000, maxdmg = 2905, bestspell = "fire"},
    {name = "crab", exp = 30, hp = 55, ratio = 0.545, maxdmg = 20, bestspell = "fire"},
    {name = "crazed beggar", exp = 35, hp = 100, ratio = 0.350, maxdmg = 25, bestspell = "death"},
    {name = "crimson frog", exp = 20, hp = 60, ratio = 0.333, maxdmg = 24, bestspell = "fire"},
    {name = "crocodile", exp = 40, hp = 105, ratio = 0.381, maxdmg = 40, bestspell = "fire"},
    {name = "crypt shambler", exp = 195, hp = 330, ratio = 0.591, maxdmg = 195, bestspell = "fire"},
    {name = "crystal spider", exp = 900, hp = 1250, ratio = 0.720, maxdmg = 358, bestspell = "energy"},
    {name = "cublarc the plunderer", exp = 400, hp = 400, ratio = 1.000, maxdmg = 0, bestspell = "death"},
    {name = "cursed gladiator", exp = 215, hp = 435, ratio = 0.494, maxdmg = 200, bestspell = "fire"},
    {name = "cyclops", exp = 150, hp = 260, ratio = 0.577, maxdmg = 105, bestspell = "death"},
    {name = "cyclops drone", exp = 200, hp = 325, ratio = 0.615, maxdmg = 180, bestspell = "earth"},
    {name = "cyclops smith", exp = 255, hp = 435, ratio = 0.586, maxdmg = 220, bestspell = "earth"},
    {name = "damaged worker golem", exp = 95, hp = 260, ratio = 0.365, maxdmg = 90, bestspell = "energy"},
    {name = "darakan the executioner", exp = 1600, hp = 3500, ratio = 0.457, maxdmg = 390, bestspell = "fire"},
    {name = "dark apprentice", exp = 100, hp = 225, ratio = 0.444, maxdmg = 100, bestspell = "death"},
    {name = "dark magician", exp = 185, hp = 325, ratio = 0.569, maxdmg = 100, bestspell = "death"},
    {name = "dark monk", exp = 145, hp = 190, ratio = 0.763, maxdmg = 150, bestspell = "fire"},
    {name = "dark torturer", exp = 4650, hp = 7350, ratio = 0.633, maxdmg = 1300, bestspell = "ice"},
    {name = "deadeye devious", exp = 500, hp = 1450, ratio = 0.345, maxdmg = 250, bestspell = "death"},
    {name = "death blob", exp = 300, hp = 320, ratio = 0.938, maxdmg = 212, bestspell = "fire"},
    {name = "deathbringer", exp = 5100, hp = 10000, ratio = 0.510, maxdmg = 1265, bestspell = "energy"},
    {name = "deathslicer", exp = 0, hp = 1, ratio = 0.000, maxdmg = 1000, bestspell = "none"},
    {name = "deathspawn", exp = 0, hp = 225, ratio = 0.000, maxdmg = 1000, bestspell = "fire"},
    {name = "deer", exp = 0, hp = 25, ratio = 0.000, maxdmg = 1, bestspell = "death"},
    {name = "defiler", exp = 3700, hp = 3650, ratio = 1.014, maxdmg = 712, bestspell = "fire"},
    {name = "demodras", exp = 6000, hp = 4500, ratio = 1.333, maxdmg = 1150, bestspell = "death"},
    {name = "demon", exp = 6000, hp = 8200, ratio = 0.732, maxdmg = 1530, bestspell = "ice"},
    {name = "demon parrot", exp = 225, hp = 360, ratio = 0.625, maxdmg = 190, bestspell = "death"},
    {name = "demon skeleton", exp = 240, hp = 400, ratio = 0.600, maxdmg = 235, bestspell = "energy"},
    {name = "demon (goblin)", exp = 25, hp = 50, ratio = 0.500, maxdmg = 30, bestspell = "death"},
    {name = "destroyer", exp = 2500, hp = 3700, ratio = 0.676, maxdmg = 700, bestspell = "ice"},
    {name = "devovorga", exp = 0, hp = 1, ratio = 0.000, maxdmg = 9400, bestspell = "death"},
    {name = "dharalion", exp = 380, hp = 380, ratio = 1.000, maxdmg = 120, bestspell = "death"},
    {name = "diabolic imp", exp = 2900, hp = 1950, ratio = 1.487, maxdmg = 870, bestspell = "ice"},
    {name = "diblis the fair", exp = 1800, hp = 1500, ratio = 1.200, maxdmg = 1500, bestspell = "fire"},
    {name = "dipthrah", exp = 2900, hp = 4200, ratio = 0.690, maxdmg = 1400, bestspell = "fire"},
    {name = "dire penguin", exp = 119, hp = 173, ratio = 0.688, maxdmg = 115, bestspell = "energy"},
    {name = "dirtbeard", exp = 375, hp = 630, ratio = 0.595, maxdmg = 225, bestspell = "fire"},
    {name = "diseased bill", exp = 300, hp = 2000, ratio = 0.150, maxdmg = 769, bestspell = "fire"},
    {name = "diseased dan", exp = 300, hp = 2000, ratio = 0.150, maxdmg = 381, bestspell = "energy"},
    {name = "diseased fred", exp = 300, hp = 2000, ratio = 0.150, maxdmg = 450, bestspell = "fire"},
    {name = "doctor perhaps", exp = 325, hp = 475, ratio = 0.684, maxdmg = 100, bestspell = "death"},
    {name = "dog", exp = 0, hp = 20, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "doom deer", exp = 200, hp = 405, ratio = 0.494, maxdmg = 155, bestspell = "death"},
    {name = "doomhowl", exp = 3750, hp = 8500, ratio = 0.441, maxdmg = 644, bestspell = "death"},
    {name = "doomsday cultist", exp = 100, hp = 125, ratio = 0.800, maxdmg = 0, bestspell = "death"},
    {name = "dracola", exp = 11000, hp = 16200, ratio = 0.679, maxdmg = 4245, bestspell = "energy"},
    {name = "dragon", exp = 700, hp = 1000, ratio = 0.700, maxdmg = 400, bestspell = "ice"},
    {name = "dragon hatchling", exp = 185, hp = 380, ratio = 0.487, maxdmg = 200, bestspell = "ice"},
    {name = "dragon lord", exp = 2100, hp = 1900, ratio = 1.105, maxdmg = 720, bestspell = "ice"},
    {name = "dragon lord hatchling", exp = 645, hp = 750, ratio = 0.860, maxdmg = 335, bestspell = "energy"},
    {name = "draken abomination", exp = 3800, hp = 6250, ratio = 0.608, maxdmg = 1000, bestspell = "energy"},
    {name = "draken elite", exp = 4200, hp = 5550, ratio = 0.757, maxdmg = 1500, bestspell = "ice"},
    {name = "draken spellweaver", exp = 2600, hp = 5000, ratio = 0.520, maxdmg = 1000, bestspell = "energy"},
    {name = "draken warmaster", exp = 2400, hp = 4150, ratio = 0.578, maxdmg = 600, bestspell = "ice"},
    {name = "drasilla", exp = 700, hp = 1320, ratio = 0.530, maxdmg = 390, bestspell = "ice"},
    {name = "dreadbeast", exp = 250, hp = 800, ratio = 0.312, maxdmg = 140, bestspell = "energy"},
    {name = "dreadmaw", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "dreadwing", exp = 3750, hp = 8500, ratio = 0.441, maxdmg = 100, bestspell = "fire"},
    {name = "dryad", exp = 190, hp = 310, ratio = 0.613, maxdmg = 120, bestspell = "fire"},
    {name = "duskbringer", exp = 2600, hp = 3000, ratio = 0.867, maxdmg = 700, bestspell = "ice"},
    {name = "dwarf", exp = 45, hp = 90, ratio = 0.500, maxdmg = 30, bestspell = "death"},
    {name = "dwarf dispenser", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "none"},
    {name = "dwarf geomancer", exp = 265, hp = 380, ratio = 0.697, maxdmg = 210, bestspell = "ice"},
    {name = "dwarf guard", exp = 165, hp = 245, ratio = 0.673, maxdmg = 140, bestspell = "death"},
    {name = "dwarf henchman", exp = 15, hp = 350, ratio = 0.043, maxdmg = 93, bestspell = "fire"},
    {name = "dwarf miner", exp = 60, hp = 120, ratio = 0.500, maxdmg = 30, bestspell = "death"},
    {name = "dwarf soldier", exp = 70, hp = 135, ratio = 0.519, maxdmg = 130, bestspell = "death"},
    {name = "dworc fleshhunter", exp = 40, hp = 85, ratio = 0.471, maxdmg = 41, bestspell = "death"},
    {name = "dworc venomsniper", exp = 35, hp = 80, ratio = 0.438, maxdmg = 17, bestspell = "fire"},
    {name = "dworc voodoomaster", exp = 55, hp = 80, ratio = 0.688, maxdmg = 90, bestspell = "fire"},
    {name = "earth elemental", exp = 450, hp = 650, ratio = 0.692, maxdmg = 328, bestspell = "fire"},
    {name = "earth overlord", exp = 2800, hp = 4000, ratio = 0.700, maxdmg = 1500, bestspell = "fire"},
    {name = "eclipse knight", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "efreet", exp = 410, hp = 550, ratio = 0.745, maxdmg = 340, bestspell = "ice"},
    {name = "elder bonelord", exp = 280, hp = 500, ratio = 0.560, maxdmg = 405, bestspell = "fire"},
    {name = "elephant", exp = 160, hp = 320, ratio = 0.500, maxdmg = 100, bestspell = "energy"},
    {name = "elf", exp = 42, hp = 100, ratio = 0.420, maxdmg = 40, bestspell = "death"},
    {name = "elf arcanist", exp = 175, hp = 220, ratio = 0.795, maxdmg = 220, bestspell = "earth"},
    {name = "elf scout", exp = 75, hp = 160, ratio = 0.469, maxdmg = 110, bestspell = "death"},
    {name = "energy elemental", exp = 550, hp = 500, ratio = 1.100, maxdmg = 582, bestspell = "earth"},
    {name = "energy overlord", exp = 2800, hp = 4000, ratio = 0.700, maxdmg = 1400, bestspell = "fire"},
    {name = "enlightened of the cult", exp = 500, hp = 700, ratio = 0.714, maxdmg = 285, bestspell = "death"},
    {name = "enraged bookworm", exp = 55, hp = 145, ratio = 0.379, maxdmg = 0, bestspell = "death"},
    {name = "enraged squirrel", exp = 0, hp = 35, ratio = 0.000, maxdmg = 6, bestspell = "death"},
    {name = "esmeralda", exp = 600, hp = 800, ratio = 0.750, maxdmg = 384, bestspell = "fire"},
    {name = "essence of darkness", exp = 30, hp = 1000, ratio = 0.030, maxdmg = 25, bestspell = "fire"},
    {name = "eternal guardian", exp = 1800, hp = 2500, ratio = 0.720, maxdmg = 300, bestspell = "energy"},
    {name = "evil mastermind", exp = 675, hp = 1295, ratio = 0.521, maxdmg = 357, bestspell = "fire"},
    {name = "evil sheep", exp = 240, hp = 350, ratio = 0.686, maxdmg = 140, bestspell = "fire"},
    {name = "evil sheep lord", exp = 340, hp = 400, ratio = 0.850, maxdmg = 118, bestspell = "fire"},
    {name = "eye of the seven", exp = 0, hp = 1, ratio = 0.000, maxdmg = 500, bestspell = "none"},
    {name = "fahim the wise", exp = 1500, hp = 2000, ratio = 0.750, maxdmg = 800, bestspell = "ice"},
    {name = "fallen mooh'tah master ghar", exp = 4400, hp = 8000, ratio = 0.550, maxdmg = 1600, bestspell = "death"},
    {name = "fatality", exp = 4285, hp = 5945, ratio = 0.721, maxdmg = 205, bestspell = "death"},
    {name = "fernfang", exp = 600, hp = 400, ratio = 1.500, maxdmg = 230, bestspell = "death"},
    {name = "ferumbras", exp = 12000, hp = 35000, ratio = 0.343, maxdmg = 2400, bestspell = "death"},
    {name = "fire devil", exp = 145, hp = 200, ratio = 0.725, maxdmg = 160, bestspell = "ice"},
    {name = "fire elemental", exp = 220, hp = 280, ratio = 0.786, maxdmg = 280, bestspell = "ice"},
    {name = "fire overlord", exp = 2800, hp = 4000, ratio = 0.700, maxdmg = 1200, bestspell = "ice"},
    {name = "flamecaller zazrak", exp = 2000, hp = 3000, ratio = 0.667, maxdmg = 560, bestspell = "ice"},
    {name = "flamethrower", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "none"},
    {name = "flamingo", exp = 0, hp = 25, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "fleabringer", exp = 0, hp = 265, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "fluffy", exp = 3550, hp = 4500, ratio = 0.789, maxdmg = 750, bestspell = "death"},
    {name = "foreman kneebiter", exp = 445, hp = 570, ratio = 0.781, maxdmg = 317, bestspell = "death"},
    {name = "freegoiz", exp = 0, hp = 1, ratio = 0.000, maxdmg = 1665, bestspell = "death"},
    {name = "frost dragon", exp = 2100, hp = 1800, ratio = 1.167, maxdmg = 700, bestspell = "energy"},
    {name = "frost dragon hatchling", exp = 745, hp = 800, ratio = 0.931, maxdmg = 380, bestspell = "energy"},
    {name = "frost giant", exp = 150, hp = 270, ratio = 0.556, maxdmg = 200, bestspell = "death"},
    {name = "frost giantess", exp = 150, hp = 275, ratio = 0.545, maxdmg = 150, bestspell = "energy"},
    {name = "frost troll", exp = 23, hp = 55, ratio = 0.418, maxdmg = 20, bestspell = "death"},
    {name = "frostfur", exp = 35, hp = 65, ratio = 0.538, maxdmg = 30, bestspell = "energy"},
    {name = "furious troll", exp = 185, hp = 245, ratio = 0.755, maxdmg = 100, bestspell = "death"},
    {name = "fury", exp = 4500, hp = 4100, ratio = 1.098, maxdmg = 800, bestspell = "death"},
    {name = "fury of the emperor", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "energy"},
    {name = "gamemaster (creature)", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "none"},
    {name = "gang member", exp = 70, hp = 295, ratio = 0.237, maxdmg = 95, bestspell = "death"},
    {name = "gargoyle", exp = 150, hp = 250, ratio = 0.600, maxdmg = 65, bestspell = "fire"},
    {name = "gazer", exp = 90, hp = 120, ratio = 0.750, maxdmg = 50, bestspell = "fire"},
    {name = "general murius", exp = 450, hp = 550, ratio = 0.818, maxdmg = 250, bestspell = "death"},
    {name = "ghastly dragon", exp = 4600, hp = 7800, ratio = 0.590, maxdmg = 1780, bestspell = "energy"},
    {name = "ghazbaran", exp = 15000, hp = 60000, ratio = 0.250, maxdmg = 5775, bestspell = "energy"},
    {name = "ghost", exp = 120, hp = 150, ratio = 0.800, maxdmg = 125, bestspell = "fire"},
    {name = "ghost rat", exp = 0, hp = 1, ratio = 0.000, maxdmg = 120, bestspell = "death"},
    {name = "ghostly apparition", exp = 0, hp = 1, ratio = 0.000, maxdmg = 6, bestspell = "none"},
    {name = "ghoul", exp = 85, hp = 100, ratio = 0.850, maxdmg = 97, bestspell = "fire"},
    {name = "giant spider", exp = 900, hp = 1300, ratio = 0.692, maxdmg = 378, bestspell = "fire"},
    {name = "gladiator", exp = 90, hp = 185, ratio = 0.486, maxdmg = 90, bestspell = "death"},
    {name = "glitterscale", exp = 700, hp = 1000, ratio = 0.700, maxdmg = 0, bestspell = "death"},
    {name = "gloombringer", exp = 0, hp = 1, ratio = 0.000, maxdmg = 3000, bestspell = "death"},
    {name = "gnarlhound", exp = 60, hp = 198, ratio = 0.303, maxdmg = 70, bestspell = "death"},
    {name = "gnorre chyllson", exp = 4000, hp = 7100, ratio = 0.563, maxdmg = 1100, bestspell = "energy"},
    {name = "goblin", exp = 25, hp = 50, ratio = 0.500, maxdmg = 35, bestspell = "earth"},
    {name = "goblin assassin", exp = 52, hp = 75, ratio = 0.693, maxdmg = 50, bestspell = "earth"},
    {name = "goblin leader", exp = 75, hp = 50, ratio = 1.500, maxdmg = 95, bestspell = "death"},
    {name = "goblin scavenger", exp = 37, hp = 60, ratio = 0.617, maxdmg = 75, bestspell = "death"},
    {name = "golgordan", exp = 10000, hp = 40000, ratio = 0.250, maxdmg = 3127, bestspell = "fire"},
    {name = "gozzler", exp = 180, hp = 240, ratio = 0.750, maxdmg = 245, bestspell = "fire"},
    {name = "grand mother foulscale", exp = 1400, hp = 1850, ratio = 0.757, maxdmg = 300, bestspell = "ice"},
    {name = "grandfather tridian", exp = 1400, hp = 1800, ratio = 0.778, maxdmg = 540, bestspell = "death"},
    {name = "gravelord oshuran", exp = 2400, hp = 3100, ratio = 0.774, maxdmg = 750, bestspell = "fire"},
    {name = "green djinn", exp = 215, hp = 330, ratio = 0.652, maxdmg = 320, bestspell = "ice"},
    {name = "green frog", exp = 0, hp = 25, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "grim reaper", exp = 5500, hp = 3900, ratio = 1.410, maxdmg = 1720, bestspell = "fire"},
    {name = "grimgor guteater", exp = 670, hp = 1155, ratio = 0.580, maxdmg = 330, bestspell = "death"},
    {name = "grorlam", exp = 2400, hp = 3000, ratio = 0.800, maxdmg = 530, bestspell = "fire"},
    {name = "grynch clan goblin", exp = 4, hp = 80, ratio = 0.050, maxdmg = 0, bestspell = "death"},
    {name = "hacker", exp = 45, hp = 430, ratio = 0.105, maxdmg = 35, bestspell = "death"},
    {name = "hairman the huge", exp = 335, hp = 600, ratio = 0.558, maxdmg = 110, bestspell = "death"},
    {name = "hand of cursed fate", exp = 5000, hp = 7500, ratio = 0.667, maxdmg = 920, bestspell = "ice"},
    {name = "harbinger of darkness", exp = 0, hp = 1, ratio = 0.000, maxdmg = 4066, bestspell = "death"},
    {name = "hatebreeder", exp = 11000, hp = 1, ratio = 11000.000, maxdmg = 1800, bestspell = "energy"},
    {name = "haunted treeling", exp = 310, hp = 450, ratio = 0.689, maxdmg = 320, bestspell = "fire"},
    {name = "haunter", exp = 4000, hp = 8500, ratio = 0.471, maxdmg = 210, bestspell = "fire"},
    {name = "hell hole", exp = 0, hp = 1, ratio = 0.000, maxdmg = 1000, bestspell = "none"},
    {name = "hellfire fighter", exp = 3900, hp = 3800, ratio = 1.026, maxdmg = 2749, bestspell = "ice"},
    {name = "hellgorak", exp = 10000, hp = 30000, ratio = 0.333, maxdmg = 1800, bestspell = "death"},
    {name = "hellhound", exp = 6800, hp = 7500, ratio = 0.907, maxdmg = 3342, bestspell = "ice"},
    {name = "hellspawn", exp = 2550, hp = 3500, ratio = 0.729, maxdmg = 515, bestspell = "ice"},
    {name = "heoni", exp = 515, hp = 900, ratio = 0.572, maxdmg = 100, bestspell = "death"},
    {name = "herald of gloom", exp = 450, hp = 450, ratio = 1.000, maxdmg = 0, bestspell = "death"},
    {name = "hero", exp = 1200, hp = 1400, ratio = 0.857, maxdmg = 360, bestspell = "death"},
    {name = "hide", exp = 240, hp = 500, ratio = 0.480, maxdmg = 144, bestspell = "fire"},
    {name = "high templar cobrass", exp = 515, hp = 410, ratio = 1.256, maxdmg = 80, bestspell = "fire"},
    {name = "hot dog", exp = 190, hp = 505, ratio = 0.376, maxdmg = 125, bestspell = "death"},
    {name = "hunter", exp = 150, hp = 150, ratio = 1.000, maxdmg = 120, bestspell = "death"},
    {name = "husky", exp = 0, hp = 140, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "hyaena", exp = 20, hp = 60, ratio = 0.333, maxdmg = 20, bestspell = "death"},
    {name = "hydra", exp = 2100, hp = 2350, ratio = 0.894, maxdmg = 750, bestspell = "energy"},
    {name = "ice golem", exp = 295, hp = 385, ratio = 0.766, maxdmg = 305, bestspell = "energy"},
    {name = "ice overlord", exp = 2800, hp = 4000, ratio = 0.700, maxdmg = 1408, bestspell = "energy"},
    {name = "ice witch", exp = 580, hp = 650, ratio = 0.892, maxdmg = 394, bestspell = "death"},
    {name = "incineron", exp = 3500, hp = 7000, ratio = 0.500, maxdmg = 1400, bestspell = "death"},
    {name = "infernal frog", exp = 190, hp = 655, ratio = 0.290, maxdmg = 42, bestspell = "death"},
    {name = "infernalist", exp = 4000, hp = 3650, ratio = 1.096, maxdmg = 120, bestspell = "ice"},
    {name = "infernatil", exp = 85000, hp = 160000, ratio = 0.531, maxdmg = 6000, bestspell = "death"},
    {name = "inky", exp = 250, hp = 600, ratio = 0.417, maxdmg = 367, bestspell = "energy"},
    {name = "insect swarm", exp = 40, hp = 50, ratio = 0.800, maxdmg = 25, bestspell = "fire"},
    {name = "irahsae", exp = 0, hp = 1, ratio = 0.000, maxdmg = 900, bestspell = "death"},
    {name = "island troll", exp = 20, hp = 50, ratio = 0.400, maxdmg = 10, bestspell = "death"},
    {name = "jagged earth elemental", exp = 1300, hp = 1500, ratio = 0.867, maxdmg = 750, bestspell = "fire"},
    {name = "juggernaut", exp = 8700, hp = 20000, ratio = 0.435, maxdmg = 2260, bestspell = "energy"},
    {name = "killer caiman", exp = 800, hp = 1500, ratio = 0.533, maxdmg = 300, bestspell = "energy"},
    {name = "killer rabbit", exp = 160, hp = 205, ratio = 0.780, maxdmg = 140, bestspell = "death"},
    {name = "kitty", exp = 0, hp = 1, ratio = 0.000, maxdmg = 117, bestspell = "none"},
    {name = "kongra", exp = 115, hp = 340, ratio = 0.338, maxdmg = 60, bestspell = "ice"},
    {name = "kongra (anti-botter)", exp = 0, hp = 20000, ratio = 0.000, maxdmg = 90, bestspell = "death"},
    {name = "koshei the deathless", exp = 0, hp = 1, ratio = 0.000, maxdmg = 531, bestspell = "fire"},
    {name = "kreebosh the exile", exp = 350, hp = 805, ratio = 0.435, maxdmg = 545, bestspell = "death"},
    {name = "lancer beetle", exp = 275, hp = 400, ratio = 0.688, maxdmg = 246, bestspell = "fire"},
    {name = "larva", exp = 44, hp = 70, ratio = 0.629, maxdmg = 36, bestspell = "fire"},
    {name = "latrivan", exp = 10000, hp = 25000, ratio = 0.400, maxdmg = 1800, bestspell = "ice"},
    {name = "lavahole", exp = 0, hp = 1, ratio = 0.000, maxdmg = 111, bestspell = "none"},
    {name = "lersatio", exp = 2500, hp = 1600, ratio = 1.562, maxdmg = 650, bestspell = "fire"},
    {name = "lethal lissy", exp = 500, hp = 1450, ratio = 0.345, maxdmg = 160, bestspell = "death"},
    {name = "leviathan", exp = 5000, hp = 6000, ratio = 0.833, maxdmg = 1471, bestspell = "energy"},
    {name = "lich", exp = 900, hp = 880, ratio = 1.023, maxdmg = 500, bestspell = "fire"},
    {name = "lion", exp = 30, hp = 80, ratio = 0.375, maxdmg = 40, bestspell = "ice"},
    {name = "lizard abomination", exp = 1350, hp = 20000, ratio = 0.068, maxdmg = 1500, bestspell = "fire"},
    {name = "lizard chosen", exp = 2200, hp = 3050, ratio = 0.721, maxdmg = 880, bestspell = "death"},
    {name = "lizard dragon priest", exp = 1320, hp = 1450, ratio = 0.910, maxdmg = 240, bestspell = "death"},
    {name = "lizard gate guardian", exp = 2000, hp = 3000, ratio = 0.667, maxdmg = 500, bestspell = "death"},
    {name = "lizard high guard", exp = 1450, hp = 1800, ratio = 0.806, maxdmg = 370, bestspell = "ice"},
    {name = "lizard legionnaire", exp = 1100, hp = 1400, ratio = 0.786, maxdmg = 460, bestspell = "ice"},
    {name = "lizard magistratus", exp = 200, hp = 1, ratio = 200.000, maxdmg = 0, bestspell = "death"},
    {name = "lizard noble", exp = 250, hp = 1, ratio = 250.000, maxdmg = 330, bestspell = "death"},
    {name = "lizard sentinel", exp = 110, hp = 265, ratio = 0.415, maxdmg = 115, bestspell = "fire"},
    {name = "lizard snakecharmer", exp = 210, hp = 325, ratio = 0.646, maxdmg = 150, bestspell = "fire"},
    {name = "lizard templar", exp = 155, hp = 410, ratio = 0.378, maxdmg = 70, bestspell = "fire"},
    {name = "lizard zaogun", exp = 1700, hp = 2955, ratio = 0.575, maxdmg = 721, bestspell = "death"},
    {name = "lord of the elements", exp = 8000, hp = 8000, ratio = 1.000, maxdmg = 715, bestspell = "fire"},
    {name = "lost soul", exp = 4000, hp = 5800, ratio = 0.690, maxdmg = 630, bestspell = "energy"},
    {name = "mad scientist", exp = 205, hp = 325, ratio = 0.631, maxdmg = 127, bestspell = "death"},
    {name = "mad sheep", exp = 0, hp = 22, ratio = 0.000, maxdmg = 1, bestspell = "fire"},
    {name = "mad technomancer", exp = 55, hp = 1800, ratio = 0.031, maxdmg = 350, bestspell = "energy"},
    {name = "madareth", exp = 10000, hp = 75000, ratio = 0.133, maxdmg = 3359, bestspell = "fire"},
    {name = "magic pillar", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "magicthrower", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "none"},
    {name = "mahrdis", exp = 3050, hp = 3900, ratio = 0.782, maxdmg = 2400, bestspell = "ice"},
    {name = "mammoth", exp = 160, hp = 320, ratio = 0.500, maxdmg = 110, bestspell = "fire"},
    {name = "man in the cave", exp = 770, hp = 485, ratio = 1.588, maxdmg = 157, bestspell = "death"},
    {name = "marid", exp = 410, hp = 550, ratio = 0.745, maxdmg = 600, bestspell = "death"},
    {name = "marziel", exp = 3000, hp = 1900, ratio = 1.579, maxdmg = 800, bestspell = "ice"},
    {name = "massacre", exp = 20000, hp = 32000, ratio = 0.625, maxdmg = 2800, bestspell = "death"},
    {name = "massive earth elemental", exp = 950, hp = 1330, ratio = 0.714, maxdmg = 438, bestspell = "fire"},
    {name = "massive energy elemental", exp = 950, hp = 1100, ratio = 0.864, maxdmg = 1050, bestspell = "earth"},
    {name = "massive fire elemental", exp = 1400, hp = 1200, ratio = 1.167, maxdmg = 0, bestspell = "ice"},
    {name = "massive water elemental", exp = 1100, hp = 1250, ratio = 0.880, maxdmg = 431, bestspell = "energy"},
    {name = "mechanical fighter", exp = 255, hp = 420, ratio = 0.607, maxdmg = 200, bestspell = "death"},
    {name = "medusa", exp = 4050, hp = 4500, ratio = 0.900, maxdmg = 1000, bestspell = "energy"},
    {name = "menace", exp = 4112, hp = 5960, ratio = 0.690, maxdmg = 215, bestspell = "death"},
    {name = "mephiles", exp = 415, hp = 415, ratio = 1.000, maxdmg = 80, bestspell = "ice"},
    {name = "mercury blob", exp = 180, hp = 150, ratio = 1.200, maxdmg = 105, bestspell = "energy"},
    {name = "merikh the slaughterer", exp = 1500, hp = 2000, ratio = 0.750, maxdmg = 700, bestspell = "ice"},
    {name = "merlkin", exp = 145, hp = 235, ratio = 0.617, maxdmg = 170, bestspell = "ice"},
    {name = "merlkin (anti-botter)", exp = 900, hp = 20000, ratio = 0.045, maxdmg = 10, bestspell = "death"},
    {name = "midnight spawn", exp = 900, hp = 1, ratio = 900.000, maxdmg = 0, bestspell = "ice"},
    {name = "midnight warrior", exp = 750, hp = 1000, ratio = 0.750, maxdmg = 250, bestspell = "fire"},
    {name = "mimic", exp = 0, hp = 30, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "minishabaal", exp = 4000, hp = 6000, ratio = 0.667, maxdmg = 800, bestspell = "death"},
    {name = "minotaur", exp = 50, hp = 100, ratio = 0.500, maxdmg = 45, bestspell = "ice"},
    {name = "minotaur archer", exp = 65, hp = 100, ratio = 0.650, maxdmg = 100, bestspell = "ice"},
    {name = "minotaur guard", exp = 160, hp = 185, ratio = 0.865, maxdmg = 100, bestspell = "death"},
    {name = "minotaur mage", exp = 150, hp = 155, ratio = 0.968, maxdmg = 205, bestspell = "death"},
    {name = "monk", exp = 200, hp = 240, ratio = 0.833, maxdmg = 140, bestspell = "fire"},
    {name = "monstor", exp = 575, hp = 960, ratio = 0.599, maxdmg = 248, bestspell = "energy"},
    {name = "mooh'tah master", exp = 0, hp = 1, ratio = 0.000, maxdmg = 700, bestspell = "ice"},
    {name = "morgaroth", exp = 15000, hp = 55000, ratio = 0.273, maxdmg = 3500, bestspell = "ice"},
    {name = "morguthis", exp = 3000, hp = 4800, ratio = 0.625, maxdmg = 1900, bestspell = "earth"},
    {name = "morik the gladiator", exp = 160, hp = 1235, ratio = 0.130, maxdmg = 310, bestspell = "death"},
    {name = "mr. punish", exp = 9000, hp = 22000, ratio = 0.409, maxdmg = 1807, bestspell = "death"},
    {name = "muddy earth elemental", exp = 450, hp = 650, ratio = 0.692, maxdmg = 450, bestspell = "fire"},
    {name = "mummy", exp = 150, hp = 240, ratio = 0.625, maxdmg = 129, bestspell = "fire"},
    {name = "munster", exp = 35, hp = 58, ratio = 0.603, maxdmg = 15, bestspell = "death"},
    {name = "mutated bat", exp = 615, hp = 900, ratio = 0.683, maxdmg = 462, bestspell = "fire"},
    {name = "mutated human", exp = 150, hp = 240, ratio = 0.625, maxdmg = 164, bestspell = "fire"},
    {name = "mutated rat", exp = 450, hp = 550, ratio = 0.818, maxdmg = 305, bestspell = "fire"},
    {name = "mutated tiger", exp = 750, hp = 1100, ratio = 0.682, maxdmg = 275, bestspell = "death"},
    {name = "mutated zalamon", exp = 0, hp = 25000, ratio = 0.000, maxdmg = 1200, bestspell = "fire"},
    {name = "necromancer", exp = 580, hp = 580, ratio = 1.000, maxdmg = 260, bestspell = "fire"},
    {name = "necropharus", exp = 1050, hp = 750, ratio = 1.400, maxdmg = 300, bestspell = "death"},
    {name = "nightmare", exp = 2150, hp = 2700, ratio = 0.796, maxdmg = 750, bestspell = "ice"},
    {name = "nightmare scion", exp = 1350, hp = 1400, ratio = 0.964, maxdmg = 420, bestspell = "ice"},
    {name = "nightslayer", exp = 250, hp = 400, ratio = 0.625, maxdmg = 0, bestspell = "ice"},
    {name = "nightstalker", exp = 500, hp = 700, ratio = 0.714, maxdmg = 260, bestspell = "death"},
    {name = "nomad", exp = 60, hp = 160, ratio = 0.375, maxdmg = 80, bestspell = "death"},
    {name = "norgle glacierbeard", exp = 2100, hp = 4300, ratio = 0.488, maxdmg = 400, bestspell = "energy"},
    {name = "novice of the cult", exp = 100, hp = 285, ratio = 0.351, maxdmg = 270, bestspell = "death"},
    {name = "omruc", exp = 2950, hp = 4300, ratio = 0.686, maxdmg = 1619, bestspell = "energy"},
    {name = "orc", exp = 25, hp = 70, ratio = 0.357, maxdmg = 35, bestspell = "earth"},
    {name = "orc berserker", exp = 195, hp = 210, ratio = 0.929, maxdmg = 200, bestspell = "death"},
    {name = "orc leader", exp = 270, hp = 450, ratio = 0.600, maxdmg = 255, bestspell = "earth"},
    {name = "orc marauder", exp = 205, hp = 235, ratio = 0.872, maxdmg = 80, bestspell = "earth"},
    {name = "orc rider", exp = 110, hp = 180, ratio = 0.611, maxdmg = 120, bestspell = "earth"},
    {name = "orc shaman", exp = 110, hp = 115, ratio = 0.957, maxdmg = 81, bestspell = "earth"},
    {name = "orc spearman", exp = 38, hp = 105, ratio = 0.362, maxdmg = 55, bestspell = "death"},
    {name = "orc warlord", exp = 670, hp = 950, ratio = 0.705, maxdmg = 450, bestspell = "earth"},
    {name = "orc warrior", exp = 50, hp = 125, ratio = 0.400, maxdmg = 60, bestspell = "death"},
    {name = "orchid frog", exp = 20, hp = 60, ratio = 0.333, maxdmg = 24, bestspell = "fire"},
    {name = "orcus the cruel", exp = 280, hp = 480, ratio = 0.583, maxdmg = 250, bestspell = "earth"},
    {name = "orshabaal", exp = 10000, hp = 20500, ratio = 0.488, maxdmg = 5000, bestspell = "ice"},
    {name = "overcharged energy element", exp = 1300, hp = 1750, ratio = 0.743, maxdmg = 895, bestspell = "earth"},
    {name = "panda", exp = 23, hp = 80, ratio = 0.287, maxdmg = 16, bestspell = "fire"},
    {name = "parrot", exp = 0, hp = 25, ratio = 0.000, maxdmg = 5, bestspell = "death"},
    {name = "penguin", exp = 1, hp = 33, ratio = 0.030, maxdmg = 3, bestspell = "energy"},
    {name = "phantasm", exp = 4400, hp = 3950, ratio = 1.114, maxdmg = 800, bestspell = "fire"},
    {name = "phrodomo", exp = 44000, hp = 80000, ratio = 0.550, maxdmg = 2000, bestspell = "fire"},
    {name = "pig", exp = 0, hp = 25, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "pillar", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "pirate buccaneer", exp = 250, hp = 425, ratio = 0.588, maxdmg = 260, bestspell = "fire"},
    {name = "pirate corsair", exp = 350, hp = 675, ratio = 0.519, maxdmg = 320, bestspell = "fire"},
    {name = "pirate cutthroat", exp = 175, hp = 325, ratio = 0.538, maxdmg = 271, bestspell = "fire"},
    {name = "pirate ghost", exp = 250, hp = 275, ratio = 0.909, maxdmg = 240, bestspell = "fire"},
    {name = "pirate marauder", exp = 125, hp = 210, ratio = 0.595, maxdmg = 180, bestspell = "fire"},
    {name = "pirate skeleton", exp = 85, hp = 190, ratio = 0.447, maxdmg = 50, bestspell = "fire"},
    {name = "plaguesmith", exp = 4500, hp = 8250, ratio = 0.545, maxdmg = 890, bestspell = "energy"},
    {name = "plaguethrower", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "none"},
    {name = "poacher", exp = 70, hp = 90, ratio = 0.778, maxdmg = 70, bestspell = "death"},
    {name = "poison spider", exp = 22, hp = 26, ratio = 0.846, maxdmg = 22, bestspell = "fire"},
    {name = "polar bear", exp = 28, hp = 85, ratio = 0.329, maxdmg = 30, bestspell = "death"},
    {name = "priestess", exp = 420, hp = 390, ratio = 1.077, maxdmg = 195, bestspell = "energy"},
    {name = "primitive", exp = 45, hp = 200, ratio = 0.225, maxdmg = 90, bestspell = "death"},
    {name = "pythius the rotten (creature)", exp = 7000, hp = 9000, ratio = 0.778, maxdmg = 1250, bestspell = "fire"},
    {name = "quara constrictor", exp = 250, hp = 450, ratio = 0.556, maxdmg = 256, bestspell = "energy"},
    {name = "quara constrictor scout", exp = 200, hp = 450, ratio = 0.444, maxdmg = 205, bestspell = "energy"},
    {name = "quara hydromancer", exp = 800, hp = 1100, ratio = 0.727, maxdmg = 825, bestspell = "energy"},
    {name = "quara hydromancer scout", exp = 800, hp = 1100, ratio = 0.727, maxdmg = 670, bestspell = "energy"},
    {name = "quara mantassin", exp = 400, hp = 800, ratio = 0.500, maxdmg = 140, bestspell = "energy"},
    {name = "quara mantassin scout", exp = 100, hp = 220, ratio = 0.455, maxdmg = 110, bestspell = "energy"},
    {name = "quara pincher", exp = 1200, hp = 1800, ratio = 0.667, maxdmg = 340, bestspell = "energy"},
    {name = "quara pincher scout", exp = 600, hp = 775, ratio = 0.774, maxdmg = 240, bestspell = "energy"},
    {name = "quara predator", exp = 1600, hp = 2200, ratio = 0.727, maxdmg = 470, bestspell = "energy"},
    {name = "quara predator scout", exp = 400, hp = 890, ratio = 0.449, maxdmg = 190, bestspell = "energy"},
    {name = "rabbit", exp = 0, hp = 15, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "rahemos", exp = 3100, hp = 3700, ratio = 0.838, maxdmg = 1850, bestspell = "fire"},
    {name = "rat", exp = 5, hp = 20, ratio = 0.250, maxdmg = 8, bestspell = "death"},
    {name = "renegade orc", exp = 270, hp = 450, ratio = 0.600, maxdmg = 180, bestspell = "death"},
    {name = "rift brood", exp = 1600, hp = 3000, ratio = 0.533, maxdmg = 270, bestspell = "death"},
    {name = "rift lord", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "rift phantom", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "rift scythe", exp = 2000, hp = 3600, ratio = 0.556, maxdmg = 1000, bestspell = "fire"},
    {name = "rift worm", exp = 1195, hp = 2800, ratio = 0.427, maxdmg = 0, bestspell = "earth"},
    {name = "roaring water elemental", exp = 1300, hp = 1750, ratio = 0.743, maxdmg = 762, bestspell = "energy"},
    {name = "rocko", exp = 3400, hp = 10000, ratio = 0.340, maxdmg = 600, bestspell = "ice"},
    {name = "rocky", exp = 190, hp = 390, ratio = 0.487, maxdmg = 80, bestspell = "fire"},
    {name = "ron the ripper", exp = 500, hp = 1500, ratio = 0.333, maxdmg = 410, bestspell = "death"},
    {name = "rottie the rotworm", exp = 40, hp = 65, ratio = 0.615, maxdmg = 25, bestspell = "death"},
    {name = "rotworm", exp = 40, hp = 65, ratio = 0.615, maxdmg = 40, bestspell = "death"},
    {name = "rotworm queen", exp = 75, hp = 105, ratio = 0.714, maxdmg = 80, bestspell = "fire"},
    {name = "rukor zad", exp = 380, hp = 380, ratio = 1.000, maxdmg = 370, bestspell = "fire"},
    {name = "sandcrawler", exp = 20, hp = 30, ratio = 0.667, maxdmg = 3, bestspell = "fire"},
    {name = "scarab", exp = 120, hp = 320, ratio = 0.375, maxdmg = 115, bestspell = "fire"},
    {name = "scorn of the emperor", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "energy"},
    {name = "scorpion", exp = 45, hp = 45, ratio = 1.000, maxdmg = 67, bestspell = "fire"},
    {name = "sea serpent", exp = 2300, hp = 1950, ratio = 1.179, maxdmg = 800, bestspell = "energy"},
    {name = "seagull", exp = 0, hp = 25, ratio = 0.000, maxdmg = 3, bestspell = "death"},
    {name = "serpent spawn", exp = 3050, hp = 3000, ratio = 1.017, maxdmg = 1400, bestspell = "fire"},
    {name = "servant golem", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "shadow hound", exp = 600, hp = 555, ratio = 1.081, maxdmg = 155, bestspell = "fire"},
    {name = "shadow of boreth", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "shadow of lersatio", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "shadow of marziel", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "shard of corruption", exp = 5, hp = 600, ratio = 0.008, maxdmg = 200, bestspell = "ice"},
    {name = "shardhead", exp = 650, hp = 800, ratio = 0.812, maxdmg = 300, bestspell = "energy"},
    {name = "sharptooth", exp = 1600, hp = 2500, ratio = 0.640, maxdmg = 500, bestspell = "energy"},
    {name = "sheep", exp = 0, hp = 20, ratio = 0.000, maxdmg = 1, bestspell = "fire"},
    {name = "shredderthrower", exp = 0, hp = 1, ratio = 0.000, maxdmg = 110, bestspell = "none"},
    {name = "sibang", exp = 105, hp = 225, ratio = 0.467, maxdmg = 95, bestspell = "ice"},
    {name = "silver rabbit", exp = 0, hp = 15, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "sir valorcrest", exp = 1800, hp = 1600, ratio = 1.125, maxdmg = 670, bestspell = "fire"},
    {name = "skeleton", exp = 35, hp = 50, ratio = 0.700, maxdmg = 30, bestspell = "fire"},
    {name = "skeleton warrior", exp = 45, hp = 65, ratio = 0.692, maxdmg = 43, bestspell = "fire"},
    {name = "skunk", exp = 3, hp = 20, ratio = 0.150, maxdmg = 8, bestspell = "death"},
    {name = "slick water elemental", exp = 450, hp = 550, ratio = 0.818, maxdmg = 542, bestspell = "energy"},
    {name = "slim", exp = 580, hp = 1025, ratio = 0.566, maxdmg = 250, bestspell = "fire"},
    {name = "slime (creature)", exp = 160, hp = 150, ratio = 1.067, maxdmg = 107, bestspell = "fire"},
    {name = "slime puddle", exp = 0, hp = 1, ratio = 0.000, maxdmg = 120, bestspell = "death"},
    {name = "smuggler", exp = 48, hp = 130, ratio = 0.369, maxdmg = 60, bestspell = "death"},
    {name = "smuggler baron silvertoe", exp = 170, hp = 280, ratio = 0.607, maxdmg = 41, bestspell = "death"},
    {name = "snake", exp = 10, hp = 15, ratio = 0.667, maxdmg = 9, bestspell = "fire"},
    {name = "snake god essence", exp = 1350, hp = 20000, ratio = 0.068, maxdmg = 1000, bestspell = "fire"},
    {name = "snake thing", exp = 4600, hp = 20000, ratio = 0.230, maxdmg = 1000, bestspell = "fire"},
    {name = "son of verminor", exp = 5900, hp = 8500, ratio = 0.694, maxdmg = 1000, bestspell = "death"},
    {name = "souleater", exp = 1300, hp = 1100, ratio = 1.182, maxdmg = 480, bestspell = "fire"},
    {name = "spawn of despair", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "spawn of devovorga", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "spectral scum", exp = 0, hp = 1, ratio = 0.000, maxdmg = 120, bestspell = "death"},
    {name = "spectre", exp = 2100, hp = 1350, ratio = 1.556, maxdmg = 820, bestspell = "fire"},
    {name = "spider", exp = 12, hp = 20, ratio = 0.600, maxdmg = 25, bestspell = "fire"},
    {name = "spirit of earth", exp = 800, hp = 1294, ratio = 0.618, maxdmg = 640, bestspell = "fire"},
    {name = "spirit of fire", exp = 950, hp = 2210, ratio = 0.430, maxdmg = 640, bestspell = "ice"},
    {name = "spirit of light", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "spirit of water", exp = 850, hp = 1517, ratio = 0.560, maxdmg = 995, bestspell = "energy"},
    {name = "spit nettle", exp = 20, hp = 150, ratio = 0.133, maxdmg = 45, bestspell = "fire"},
    {name = "spite of the emperor", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "energy"},
    {name = "splasher", exp = 500, hp = 1000, ratio = 0.500, maxdmg = 808, bestspell = "energy"},
    {name = "squirrel", exp = 0, hp = 20, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "stalker", exp = 90, hp = 120, ratio = 0.750, maxdmg = 100, bestspell = "fire"},
    {name = "stampor", exp = 780, hp = 1200, ratio = 0.650, maxdmg = 350, bestspell = "death"},
    {name = "stone golem", exp = 160, hp = 270, ratio = 0.593, maxdmg = 110, bestspell = "ice"},
    {name = "stonecracker", exp = 3500, hp = 5500, ratio = 0.636, maxdmg = 840, bestspell = "death"},
    {name = "svoren the mad", exp = 3000, hp = 6300, ratio = 0.476, maxdmg = 550, bestspell = "death"},
    {name = "swamp troll", exp = 25, hp = 55, ratio = 0.455, maxdmg = 14, bestspell = "fire"},
    {name = "tarantula", exp = 120, hp = 225, ratio = 0.533, maxdmg = 90, bestspell = "fire"},
    {name = "target dummy", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "teleskor", exp = 70, hp = 80, ratio = 0.875, maxdmg = 30, bestspell = "death"},
    {name = "teneshpar", exp = 0, hp = 1, ratio = 0.000, maxdmg = 800, bestspell = "fire"},
    {name = "terramite", exp = 160, hp = 365, ratio = 0.438, maxdmg = 116, bestspell = "fire"},
    {name = "terror bird", exp = 150, hp = 300, ratio = 0.500, maxdmg = 90, bestspell = "fire"},
    {name = "thalas", exp = 2950, hp = 4100, ratio = 0.720, maxdmg = 1400, bestspell = "fire"},
    {name = "the abomination", exp = 0, hp = 1, ratio = 0.000, maxdmg = 1300, bestspell = "death"},
    {name = "the axeorcist", exp = 4005, hp = 5100, ratio = 0.785, maxdmg = 706, bestspell = "death"},
    {name = "the big bad one", exp = 170, hp = 300, ratio = 0.567, maxdmg = 100, bestspell = "death"},
    {name = "the blightfather", exp = 600, hp = 400, ratio = 1.500, maxdmg = 0, bestspell = "death"},
    {name = "the bloodtusk", exp = 300, hp = 600, ratio = 0.500, maxdmg = 120, bestspell = "fire"},
    {name = "the collector", exp = 100, hp = 340, ratio = 0.294, maxdmg = 46, bestspell = "death"},
    {name = "the count", exp = 450, hp = 1250, ratio = 0.360, maxdmg = 500, bestspell = "fire"},
    {name = "the dark dancer", exp = 435, hp = 855, ratio = 0.509, maxdmg = 90, bestspell = "energy"},
    {name = "the dreadorian", exp = 4000, hp = 1, ratio = 4000.000, maxdmg = 388, bestspell = "death"},
    {name = "the evil eye", exp = 750, hp = 1200, ratio = 0.625, maxdmg = 1169, bestspell = "death"},
    {name = "the frog prince", exp = 1, hp = 55, ratio = 0.018, maxdmg = 1, bestspell = "death"},
    {name = "the hag", exp = 510, hp = 935, ratio = 0.545, maxdmg = 100, bestspell = "death"},
    {name = "the hairy one", exp = 115, hp = 325, ratio = 0.354, maxdmg = 70, bestspell = "fire"},
    {name = "the halloween hare", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "the handmaiden", exp = 7500, hp = 1, ratio = 7500.000, maxdmg = 2020, bestspell = "death"},
    {name = "the horned fox", exp = 300, hp = 265, ratio = 1.132, maxdmg = 120, bestspell = "death"},
    {name = "the imperor", exp = 8000, hp = 15000, ratio = 0.533, maxdmg = 2000, bestspell = "death"},
    {name = "the keeper", exp = 3205, hp = 25000, ratio = 0.128, maxdmg = 1400, bestspell = "fire"},
    {name = "the many", exp = 4000, hp = 1, ratio = 4000.000, maxdmg = 0, bestspell = "death"},
    {name = "the masked marauder", exp = 3500, hp = 6800, ratio = 0.515, maxdmg = 930, bestspell = "death"},
    {name = "the mutated pumpkin", exp = 35000, hp = 550000, ratio = 0.064, maxdmg = 300, bestspell = "death"},
    {name = "the noxious spawn", exp = 6000, hp = 9500, ratio = 0.632, maxdmg = 1350, bestspell = "death"},
    {name = "the obliverator", exp = 6000, hp = 9500, ratio = 0.632, maxdmg = 1000, bestspell = "earth"},
    {name = "the old whopper", exp = 750, hp = 785, ratio = 0.955, maxdmg = 175, bestspell = "death"},
    {name = "the old widow", exp = 4200, hp = 3200, ratio = 1.312, maxdmg = 1050, bestspell = "death"},
    {name = "the pit lord", exp = 2500, hp = 4500, ratio = 0.556, maxdmg = 568, bestspell = "ice"},
    {name = "the plasmother", exp = 8300, hp = 1, ratio = 8300.000, maxdmg = 1000, bestspell = "death"},
    {name = "the ruthless herald", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "none"},
    {name = "the snapper", exp = 150, hp = 300, ratio = 0.500, maxdmg = 60, bestspell = "fire"},
    {name = "the voice of ruin", exp = 3900, hp = 5500, ratio = 0.709, maxdmg = 0, bestspell = "death"},
    {name = "the weakened count", exp = 450, hp = 740, ratio = 0.608, maxdmg = 283, bestspell = "fire"},
    {name = "thief (creature)", exp = 5, hp = 60, ratio = 0.083, maxdmg = 32, bestspell = "death"},
    {name = "thieving squirrel", exp = 0, hp = 55, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "thornback tortoise", exp = 150, hp = 300, ratio = 0.500, maxdmg = 112, bestspell = "fire"},
    {name = "thul", exp = 2700, hp = 2950, ratio = 0.915, maxdmg = 302, bestspell = "energy"},
    {name = "tibia bug", exp = 50, hp = 270, ratio = 0.185, maxdmg = 70, bestspell = "death"},
    {name = "tiger", exp = 40, hp = 75, ratio = 0.533, maxdmg = 40, bestspell = "death"},
    {name = "tiquandas revenge", exp = 2635, hp = 1800, ratio = 1.464, maxdmg = 910, bestspell = "fire"},
    {name = "tirecz", exp = 6000, hp = 25000, ratio = 0.240, maxdmg = 1200, bestspell = "death"},
    {name = "toad", exp = 60, hp = 135, ratio = 0.444, maxdmg = 48, bestspell = "fire"},
    {name = "tormented ghost", exp = 5, hp = 210, ratio = 0.024, maxdmg = 170, bestspell = "death"},
    {name = "tortoise", exp = 90, hp = 185, ratio = 0.486, maxdmg = 50, bestspell = "fire"},
    {name = "tortoise (anti-botter)", exp = 0, hp = 1, ratio = 0.000, maxdmg = 100, bestspell = "fire"},
    {name = "tremorak", exp = 1300, hp = 10000, ratio = 0.130, maxdmg = 660, bestspell = "fire"},
    {name = "troll", exp = 20, hp = 50, ratio = 0.400, maxdmg = 24, bestspell = "death"},
    {name = "troll champion", exp = 40, hp = 75, ratio = 0.533, maxdmg = 35, bestspell = "death"},
    {name = "troll legionnaire", exp = 140, hp = 210, ratio = 0.667, maxdmg = 170, bestspell = "death"},
    {name = "undead dragon", exp = 7200, hp = 8350, ratio = 0.862, maxdmg = 1975, bestspell = "energy"},
    {name = "undead gladiator", exp = 800, hp = 1000, ratio = 0.800, maxdmg = 385, bestspell = "earth"},
    {name = "undead jester", exp = 5, hp = 355, ratio = 0.014, maxdmg = 3, bestspell = "energy"},
    {name = "undead mine worker", exp = 45, hp = 65, ratio = 0.692, maxdmg = 33, bestspell = "fire"},
    {name = "undead minion", exp = 550, hp = 850, ratio = 0.647, maxdmg = 560, bestspell = "death"},
    {name = "undead prospector", exp = 85, hp = 100, ratio = 0.850, maxdmg = 50, bestspell = "fire"},
    {name = "ungreez", exp = 500, hp = 8200, ratio = 0.061, maxdmg = 1500, bestspell = "ice"},
    {name = "ushuriel", exp = 10000, hp = 40000, ratio = 0.250, maxdmg = 2600, bestspell = "fire"},
    {name = "valkyrie", exp = 85, hp = 190, ratio = 0.447, maxdmg = 120, bestspell = "death"},
    {name = "vampire", exp = 305, hp = 475, ratio = 0.642, maxdmg = 350, bestspell = "fire"},
    {name = "vampire bride", exp = 1050, hp = 1200, ratio = 0.875, maxdmg = 570, bestspell = "fire"},
    {name = "vampire pig", exp = 165, hp = 305, ratio = 0.541, maxdmg = 190, bestspell = "death"},
    {name = "vashresamun", exp = 2950, hp = 4000, ratio = 0.738, maxdmg = 1300, bestspell = "fire"},
    {name = "verminor", exp = 80000, hp = 160000, ratio = 0.500, maxdmg = 601000, bestspell = "death"},
    {name = "vulnerable cocoon", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "wailing widow", exp = 450, hp = 850, ratio = 0.529, maxdmg = 260, bestspell = "fire"},
    {name = "war golem", exp = 2750, hp = 4300, ratio = 0.640, maxdmg = 800, bestspell = "energy"},
    {name = "war wolf", exp = 55, hp = 140, ratio = 0.393, maxdmg = 50, bestspell = "ice"},
    {name = "warlock", exp = 4000, hp = 3500, ratio = 1.143, maxdmg = 810, bestspell = "death"},
    {name = "warlord ruzad", exp = 1700, hp = 2500, ratio = 0.680, maxdmg = 0, bestspell = "death"},
    {name = "wasp", exp = 24, hp = 35, ratio = 0.686, maxdmg = 20, bestspell = "fire"},
    {name = "water elemental", exp = 650, hp = 550, ratio = 1.182, maxdmg = 560, bestspell = "energy"},
    {name = "weak eclipse knight", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "weak gloombringer", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "weak harbinger of darkness", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "weak spawn of despair", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "death"},
    {name = "webster", exp = 1200, hp = 1750, ratio = 0.686, maxdmg = 270, bestspell = "energy"},
    {name = "werewolf", exp = 1900, hp = 1955, ratio = 0.972, maxdmg = 515, bestspell = "fire"},
    {name = "wild warrior", exp = 60, hp = 135, ratio = 0.444, maxdmg = 70, bestspell = "death"},
    {name = "winter wolf", exp = 20, hp = 30, ratio = 0.667, maxdmg = 20, bestspell = "death"},
    {name = "wisp", exp = 0, hp = 115, ratio = 0.000, maxdmg = 7, bestspell = "fire"},
    {name = "witch", exp = 120, hp = 300, ratio = 0.400, maxdmg = 115, bestspell = "death"},
    {name = "wolf", exp = 18, hp = 25, ratio = 0.720, maxdmg = 19, bestspell = "death"},
    {name = "worker golem", exp = 1250, hp = 1470, ratio = 0.850, maxdmg = 361, bestspell = "energy"},
    {name = "wrath of the emperor", exp = 0, hp = 1, ratio = 0.000, maxdmg = 0, bestspell = "energy"},
    {name = "wyrm", exp = 1550, hp = 1825, ratio = 0.849, maxdmg = 500, bestspell = "death"},
    {name = "wyvern", exp = 515, hp = 795, ratio = 0.648, maxdmg = 140, bestspell = "death"},
    {name = "xenia", exp = 255, hp = 200, ratio = 1.275, maxdmg = 50, bestspell = "death"},
    {name = "yaga the crone", exp = 375, hp = 620, ratio = 0.605, maxdmg = 60, bestspell = "death"},
    {name = "yakchal", exp = 4400, hp = 5000, ratio = 0.880, maxdmg = 1000, bestspell = "energy"},
    {name = "yalahari (creature)", exp = 5, hp = 150, ratio = 0.033, maxdmg = 0, bestspell = "fire"},
    {name = "yeti", exp = 460, hp = 950, ratio = 0.484, maxdmg = 555, bestspell = "earth"},
    {name = "young sea serpent", exp = 1000, hp = 1050, ratio = 0.952, maxdmg = 700, bestspell = "death"},
    {name = "zarabustor", exp = 8000, hp = 5100, ratio = 1.569, maxdmg = 1800, bestspell = "death"},
    {name = "zevelon duskbringer", exp = 1800, hp = 1400, ratio = 1.286, maxdmg = 1000, bestspell = "fire"},
    {name = "zombie", exp = 280, hp = 500, ratio = 0.560, maxdmg = 203, bestspell = "fire"},
    {name = "zoralurk", exp = 0, hp = 1, ratio = 0.000, maxdmg = 2587, bestspell = "ice"},
    {name = "zugurosh", exp = 10000, hp = 95000, ratio = 0.105, maxdmg = 1866, bestspell = "energy"},
    {name = "zulazza the corruptor", exp = 9800, hp = 28000, ratio = 0.350, maxdmg = 3700, bestspell = "fire"},
    {name = "skeleton", exp = 35, hp = 50, ratio = 0.700, maxdmg = 30, bestspell = "fire"},
}

