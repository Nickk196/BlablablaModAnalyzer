[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { [Console]::SetBufferSize(150, 9999) } catch {}
try { [Console]::SetWindowSize(150, 30) } catch {}
try {
    $r = $Host.UI.RawUI; $b = $r.BufferSize; $b.Width = 150; $b.Height = 9999
    $r.BufferSize = $b; $w = $r.WindowSize; $w.Width = 150; $w.Height = 30; $r.WindowSize = $w
} catch {}
Clear-Host

Write-Host ""
Write-Host "   ██████╗ ██╗      █████╗ ██████╗ ██╗      █████╗ ██████╗ ██╗      █████╗ " -ForegroundColor Magenta
Write-Host "   ██╔══██╗██║     ██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║     ██╔══██╗" -ForegroundColor Magenta
Write-Host "   ██████╔╝██║     ███████║██████╔╝██║     ███████║██████╔╝██║     ███████║" -ForegroundColor Magenta
Write-Host "   ██╔══██╗██║     ██╔══██║██╔══██╗██║     ██╔══██║██╔══██╗██║     ██╔══██║" -ForegroundColor Magenta
Write-Host "   ██████╔╝███████╗██║  ██║██████╔╝███████╗██║  ██║██████╔╝███████╗██║  ██║" -ForegroundColor DarkMagenta
Write-Host "   ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝" -ForegroundColor DarkMagenta
Write-Host ""
Write-Host "                          Mod Analyzer" -ForegroundColor White
Write-Host ""
Write-Host "   ┌──────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "   │                                                                                      │" -ForegroundColor DarkGray
Write-Host "   │" -ForegroundColor DarkGray -NoNewline; Write-Host "      BlablablaModAnalyzer " -ForegroundColor Magenta -NoNewline
Write-Host "│ " -ForegroundColor DarkGray -NoNewline; Write-Host "v2.2" -ForegroundColor DarkGray -NoNewline
Write-Host "                                          │" -ForegroundColor DarkGray
Write-Host "   │" -ForegroundColor DarkGray -NoNewline; Write-Host "      Minecraft Mod Scanner " -ForegroundColor DarkMagenta -NoNewline
Write-Host "│" -ForegroundColor DarkGray
Write-Host "   │                                                                                      │" -ForegroundColor DarkGray
Write-Host "   └──────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
Write-Host ""
Write-Host "       " -NoNewline; Write-Host "[ — MOD SCAN ]" -ForegroundColor Magenta
Write-Host "   ─────────────────────────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  For any errors, contact me on Discord" -ForegroundColor DarkMagenta
Write-Host ""

Write-Host "  Path " -ForegroundColor DarkGray -NoNewline; Write-Host "(leave blank for default)" -ForegroundColor DarkMagenta
Write-Host "  > " -ForegroundColor Magenta -NoNewline; $modsPath = Read-Host
if ([string]::IsNullOrWhiteSpace($modsPath)) {
    $modsPath = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Continuing with " -NoNewline; Write-Host $modsPath -ForegroundColor White; Write-Host
}
if (-not (Test-Path $modsPath -PathType Container)) {
    Write-Host "❌ Invalid Path!" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 1
}

$activeModules = @("Scanning Mods")
Write-Host ""; Write-Host "  Modules  : " -ForegroundColor DarkGray -NoNewline
Write-Host ($activeModules -join "  ·  ") -ForegroundColor Magenta
Add-Type -AssemblyName System.IO.Compression.FileSystem

# ═════════════════════════════════════════════════════════
#  CLEAN MOD WHITELIST
# ═════════════════════════════════════════════════════════
$script:cleanModWhitelist = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    "sodium","lithium","iris","fabric-api","modmenu","ferrite-core","lazydfu","starlight",
    "entityculling","memoryleakfix","krypton","c2me-fabric","smoothboot-fabric","immediatelyfast",
    "noisium","indium","sodium-extra","rei","jei","appleskin","dynamic-fps","fpsreducer",
    "IAS","IAS-Fabric","ias","ias-fabric","optiboxes","ukulib","TierTagger","tiertagger",
    "silicon","Silicon","motionblur","ravenclawspingequalizer","threadtweak","entity_texture_features",
    "citresewn","rendervis","modelfix","phosphor","noisium","immediatelyfast",
    "creamykeys","CreamyKeys","vmp","vmp-fabric","lithium","journeymap","xaerominimap","xaeroworldmap",
    "betterthirdperson","carpet","tweakeroo","syncmatica","minihud","litematica","malilib",
    "replaymod","optifine","optifabric","continuity","lambdynamiclights","wthit","jade",
    "architectury","cloth-config","kotlin-for-forge","geckolib","patchouli",
    "yetanotherconfiglib","yet-another-config-lib","yaclv3","yacl",
    "modernfix","modern-fix","voicechat","simple-voice-chat","notenoughanimations",
    "shulkerboxtooltip","satin","celestial","morechathistory","wi-zoom","wizoom",
    "crosshairaddons","armor-hud-numbers","ukus-armor-hud","totemtweaks",
    "ferritecore","ferrite-core"
) | ForEach-Object { [void]$script:cleanModWhitelist.Add($_) }

function Get-ModBaseName { param([string]$FileName)
    $base = [System.IO.Path]::GetFileNameWithoutExtension($FileName)
    $base = $base -replace '[-_][0-9][0-9A-Za-z.\-+_]*$', ''
    return $base.ToLower()
}

# ═════════════════════════════════════════════════════════
#  DATA LISTS
# ═════════════════════════════════════════════════════════
$suspiciousPatterns = @(
    'AimAssist','AutoAnchor','AutoCrystal','AutoDoubleHand','AutoHitCrystal','AutoPot','AutoTotem','AutoArmor','InventoryTotem',
    'JumpReset','LegitTotem','PingSpoof','SelfDestruct','ShieldBreaker','TriggerBot','AxeSpam','WebMacro',
    'WalskyOptimizer','WalksyOptimizer','walsky.optimizer','WalksyCrystalOptimizerMod','Donut','Replace Mod',
    'ShieldDisabler','SilentAim','Totem Hit','Wtap','FakeLag','BlockESP','dev.krypton','Virgin','AntiMissClick',
    'LagReach','PopSwitch','SprintReset','ChestSteal','AntiBot','AirAnchor','FakeInv','HoverTotem','AutoClicker',
    'PackSpoof','Antiknockback','catlean','Argon','AuthBypass','Asteria','Prestige','MaceSwap','DoubleAnchor',
    'AutoTPA','BaseFinder','Xenon','gypsy','imgui','imgui.gl3','imgui.glfw','BowAim','Criticals','Fakenick',
    'FakeItem','invsee','ItemExploit','Hellion','hellion','LicenseCheckMixin','obfuscatedAuth','phantom-refmap.json','xyz.greaj',
    "じ.class","ふ.class","ぶ.class","ぷ.class","た.class","ね.class","そ.class","な.class","ど.class","ぐ.class",
    "ず.class","で.class","つ.class","べ.class","せ.class","と.class","み.class","び.class","す.class","の.class",
    'org.chainlibs.module.impl.modules.Crystal.Y','org.chainlibs.module.impl.modules.Crystal.bF',
    'org.chainlibs.module.impl.modules.Crystal.bM','org.chainlibs.module.impl.modules.Crystal.bY',
    "org.chainlibs.module.impl.modules.Crystal.bq",'org.chainlibs.module.impl.modules.Crystal.cv',
    'org.chainlibs.module.impl.modules.Crystal.o','org.chainlibs.module.impl.modules.Blatant.I',
    'org.chainlibs.module.impl.modules.Blatant.bR','org.chainlibs.module.impl.modules.Blatant.bx',
    'org.chainlibs.module.impl.modules.Blatant.cj','org.chainlibs.module.impl.modules.Blatant.dk'
)

$script:cheatStrings = @(
    "AutoCrystal","autocrystal","auto crystal","cw crystal","dontPlaceCrystal","dontBreakCrystal",
    "AutoHitCrystal","autohitcrystal","canPlaceCrystalServer","healPotSlot",
    "AutoAnchor","autoanchor","auto anchor","DoubleAnchor","hasGlowstone","HasAnchor",
    "anchortweaks","anchor macro","safe anchor","safeanchor","SafeAnchor","AirAnchor","anchorMacro",
    "AutoTotem","autototem","auto totem","InventoryTotem","inventorytotem","HoverTotem","hover totem","legittotem",
    "AutoPot","autopot","auto pot","speedPotSlot","strengthPotSlot","AutoArmor","autoarmor","auto armor","AutoPotRefill",
    "preventSwordBlockBreaking","preventSwordBlockAttack","ShieldDisabler","ShieldBreaker","Breaking shield with axe...",
    "AutoDoubleHand","autodoublehand","auto double hand","Failed to switch to mace after axe!",
    "AutoMace","MaceSwap","SpearSwap","StunSlam","JumpReset","axespam","axe spam",
    "EndCrystalItemMixin","findKnockbackSword","attackRegisteredThisClick",
    "AimAssist","aimassist","aim assist","triggerbot","trigger bot","Silent Rotations","SilentRotations",
    "FakeInv","swapBackToOriginalSlot","FakeLag","fakePunch","Fake Punch",
    "webmacro","web macro","AntiWeb","AutoWeb","lvstrng","dqrkis",
    "WalksyCrystalOptimizerMod","WalksyOptimizer","WalskyOptimizer","autoCrystalPlaceClock",
    "AutoFirework","ElytraSwap","FastXP","FastExp","NoJumpDelay",
    "PackSpoof","Antiknockback","catlean","AuthBypass","obfuscatedAuth","LicenseCheckMixin",
    "BaseFinder","ItemExploit","FreezePlayer","LWFH Crystal","KeyPearl","LootYeeter","FastPlace","AutoBreach",
    "setBlockBreakingCooldown","getBlockBreakingCooldown","blockBreakingCooldown",
    "onBlockBreaking","setItemUseCooldown","setSelectedSlot","invokeDoAttack","invokeDoItemUse","invokeOnMouseButton",
    "onPushOutOfBlocks","onIsGlowing","Automatically switches to sword when hitting with totem",
    "arrayOfString","POT_CHEATS","Dqrkis Client","Entity.isGlowing","Activate Key","Click Simulation","On RMB",
    "No Count Glitch","No Bounce","NoBounce","Place Delay","Break Delay","Fast Mode","Place Chance",
    "Break Chance","Stop On Kill","damagetick","Anti Weakness","Particle Chance","Trigger Key",
    "Switch Delay","Totem Slot","Smooth Rotations","Use Easing","Easing Strength","While Use",
    "Glowstone Delay","Glowstone Chance","Explode Delay","Explode Chance","Explode Slot","Only Charge",
    "Anchor Macro","Reach Distance","Min Height","Min Fall Speed","Attack Delay","Breach Delay",
    "Require Elytra","Auto Switch Back","Check Line of Sight","Only When Falling","Require Crit",
    "Show Status Display","Stop On Crystal","Check Shield","On Pop","Check Players","Predict Crystals",
    "Check Aim","Check Items","Activates Above","Blatant","Force Totem","Stay Open For",
    "Auto Inventory Totem","Only On Pop","Vertical Speed","Hover Totem","Swap Speed","Strict One-Tick",
    "Mace Priority","Min Totems","Min Pearls","Totem First","Drop Interval","Random Pattern","Loot Yeeter",
    "Horizontal Aim Speed","Vertical Aim Speed","Include Head","Web Delay","Holding Web",
    "Not When Affects Player","Hit Delay","Require Hold Axe","placeInterval","breakInterval","stopOnKill",
    "activateOnRightClick","holdCrystal","Macro Key",
    "KillAura","ClickAura","MultiAura","ForceField","LegitAura","AimBot","AutoAim","SilentAim","AimLock","HeadSnap",
    "CrystalAura","AnchorAura","AnchorFill","AnchorPlace","BedAura","AutoBed","BedBomb","BedPlace",
    "BowAimbot","BowSpam","AutoBow","AutoCrit","CritBypass","AlwaysCrit","CriticalHit",
    "ReachHack","ExtendReach","LongReach","HitboxExpand","AntiKB","NoKnockback","GrimVelocity","GrimDisabler",
    "VelocitySpoof","KBReduce","OffhandTotem","TotemSwitch","AutoWeapon","AutoSword","AutoCity","Burrow","SelfTrap",
    "HoleFiller","AntiSurround","AntiBurrow","WTap","TargetStrafe","AutoGap","AutoPearl",
    "FlyHack","CreativeFlight","BoatFly","PacketFly","AirJump","SpeedHack","BHop","BunnyHop",
    "AntiFall","NoFallDamage","StepHack","FastClimb","AutoStep","HighStep","WaterWalk","LiquidWalk","LavaWalk",
    "NoSlow","NoSlowdown","NoWeb","NoSoulSand","WallHack","ElytraSpeed","InstantElytra",
    "ScaffoldWalk","FastBridge","AutoBridge","Nuker","NukerLegit","InstantBreak","GhostHand","NoSwing",
    "PlaceAssist","AirPlace","AutoPlace","InstantPlace","PlayerESP","MobESP","ItemESP","StorageESP","ChestESP",
    "Tracers","NameTagsHack","XRayHack","OreFinder","CaveFinder","OreESP","NewChunks","TunnelFinder",
    "TargetHUD","ReachDisplay","DoubleClicker","JitterClick","ButterflyClick","CPSBoost",
    "ChestStealer","InvManager","InvMovebypass","AutoSprint","AntiAFK","FakeLatency","FakePing",
    "SpoofRotation","PositionSpoof","GameSpeed","SpeedTimer",
    "GrimBypass","VulcanBypass","MatrixBypass","AACBypass","VerusDisabler","IntaveBypass","WatchdogBypass",
    "PacketMine","PacketWalk","PacketSneak","PacketCancel","PacketDupe","PacketSpam",
    "SelfDestruct","HideClient","SessionStealer","TokenLogger","TokenGrabber","DiscordToken",
    "ReverseShell","C2Server","KeyLogger","StashFinder","TrailFinder",
    "imgui.binding","imgui.gl3","imgui.glfw","JNativeHook","GlobalScreen","NativeKeyListener",
    "client-refmap.json","cheat-refmap.json","phantom-refmap.json",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==",
    "meteordevelopment","cc/novoline","com/alan/clients","club/maxstats","wtf/moonlight",
    "me/zeroeightsix/kami","net/ccbluex","today/opai","net/minecraft/injection",
    "org/chainlibs/module/impl/modules","xyz/greaj","com/cheatbreaker",
    "doomsdayclient","DoomsdayClient","doomsday.jar","novaclient","api.novaclient.lol",
    "WalksyOptimizer","vape.gg","vapeclient","VapeClient","VapeLite","intent.store","IntentClient",
    "rise.today","riseclient.com","meteor-client","meteorclient","meteordevelopment.meteorclient",
    "liquidbounce","fdp-client","net.ccbluex","novoware","novoclient","aristois","impactclient","azura",
    "pandaware","moonClient","astolfo","futureClient","konas","rusherhack","inertia","exhibition",
    "sessionstealer","tokengrabber","webhookstealer","cookiethief","discordstealer","keylogger",
    "iplogger","cryptominer","reverseShell","backdoormod","exploitmod","ratmod","ransomware",
    "sendWebhook","exfiltrate","connectBack","callHome","grabToken","stealSession","accountstealer",
    "discord/token","grabber/cookie","grab_cookies","stealerutils","sendToWebhook","postDiscord",
    "webhookurl","discordwebhook",
    "crasher","lagmachine","booksploit","signcrasher","entityspammer","nukermod","worldnuker",
    "tntmod","bedexplode","anchorexplode","injectClass","modifyBytecode","hookMethod",
    "attachAgent","VirtualMachine.attach",
    "FLOW_OBFUSCATION","STRING_ENCRYPTION","RESOURCE_ENCRYPTION",
    "skidfuscator","me/itzsomebody","radon/transform","bozar/","paramorphism","zelix/klassmaster",
    "allatori","dasho","com/icqm/smoke","dev.krypton","dev.gambleclient","com.cheatbreaker",
    "spoofVersion","brandOverride","overrideBrand","fakeClientBrand","brandSpoof","versionSpoof",
    "cancelPacket","dropPacket","suppressPacket","blockPacket","spoofPacket","injectPacket",
    "sendFakePacket","sendSilentPacket","bypassAC","bypass_ac","evadeAC","evadeAnticheat",
    "isGrimAC","isNoCheat","isAAC","isSpartanAC","isIntave","grimBypass","ncpBypass","aacBypass",
    "spartanBypass","checkAnticheat","detectAnticheat","getAnticheat","GrimBypass","NCPBypass",
    "AACBypass","IntaveBypass",
    "setTimerSpeed","timerSpeed","Timer.timerSpeed","setTickRate",
    "overrideTickRate","fakeTickCount","tickBoost","hitboxExpand","expandHitbox",
    "suppressKnockback","cancelKnockback","noKnockback","setVelocity(0","zeroVelocity","ignoreKnockback",
    "antiKnockback","KnockbackModifier","noVelocity",
    "renderPlayerSpoofed","spoofRender","hideFromRender",
    "fakeGlowing","GlowBypass","glowBypass","baritone.bypass","pathfindBypass","suppressPathfind",
    "bypassLicense","fakeAuth","spoofSession","AltManager","grimac","GrimAC","grim-api","ac.grim",
    "game.grim","setGrimFlag","rotationBypass","fakeYaw","fakePitch","spoofYaw","spoofPitch",
    "ＡｕﾄＣﾞｲｽﾀ｡ﾞ","Ａｕﾄ Ｃﾞｲｽﾀ｡ﾞ","ＡｕﾄＨｲﾄＣﾞｲｽﾀ｡ﾞ","ＡｕﾄＡｮｃﾞｮﾞ","Ａｕﾄ Ａｮｃﾞｮﾞ",
    "＄ｏｕｂﾞﾞｅＡｮｃﾞｮﾞ","＄ｏｕｂﾞﾞｅ Ａｮｃﾞｮﾞ","ＳａﾇｪＡＡｮｃﾞｮﾞ","Ｓａｆｅ Ａｮｃﾞｮﾞ",
    "Ａｮｃﾞｮﾞ Ｍ｡ｃﾞｮﾞ","anchorMacro","ＡｕﾄＴｵﾃｪｭ","Ａｕﾄ Ｔｵﾃｪｭ","Ｈｵｶﾞﾘ Ｔｵﾃｪｭ",
    "ＩｎｶﾝﾄﾝｮﾞｙＴｵﾃｪｭ","ＡｕﾄＰｵﾄ","Ａｕﾄ Ｐｵﾄ","Ａｕﾄ Ｐｵﾄ ２ｪﾌｲﾞ","ＡｕﾄＡｾﾞ",
    "Ｓﾞｲｪﾞﾞ＄ｲｻ｡ｂﾞ","Ｓﾞｲｪﾞﾞ ＄ｲｻ｡ｂﾞ","Ａｕﾄ＄ｵｳｂﾞﾞＨ｡ﾝﾄ","Ａｕﾄ ＄ｵｳｂﾞﾞ Ｈ｡ﾝﾄ",
    "ＡｕﾄＣｲｯｪｹｹーｯ","ＡｕﾄＭ｡ｃｪ","Ｍ｡ｃｪＳｗ｡ﾇ","Ｓﾟｪｱｲ Ｓｗ｡ﾇ","Ｓﾄｰﾝ Ｓﾞ｡ｭ",
    "ＡｲｵＡｽｽﾞ","Ａｲｳ Ａｽｽﾞ","ＴﾞｲｶﾞﾞﾞＢｵﾄ","Ｓｲﾞｭﾝﾄ ﾝｵﾀｴｵ｝","Ｆ｡ｹＬ｡ｶﾞ","Ｆ｡ｋｪ Ｐｵﾝｳﾞﾞ",
    "Ａﾝﾄｲ Ｗｪｂ","ＡｵﾄＷｪｂ","Ｗ｡ﾞｷｽｹ Ｏﾟﾄｵﾞ","ＬＷＦＨ Ｃﾞｲｽﾌ｡ﾞ","Ｌｵｵｵ Ｙｪｪﾄﾞﾞ",
    "Ａｵﾄ Ｂﾚｾ｡ｃﾞ","Ｆｲｵｪｪﾞｽﾞ Ｐﾞｱｴﾞｪｲ"
)

$script:contextOnlyStrings = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
@(
    "HttpClient","HttpURLConnection","openConnection","URLConnection",
    "getOutputStream","getInputStream","ProcessBuilder","powershell.exe",
    "Runtime.exec","cmd.exe"
) | ForEach-Object { [void]$script:contextOnlyStrings.Add($_) }

$script:knownCheatFileTokens = @(
    "doomsday","doomsdayclient","dqrkis","dqrk",
    "vape","vapeclient","vape-client","vapelite",
    "meteor","meteorclient","meteor-client",
    "liquidbounce","liquid-bounce",
    "wurst","wurst-client",
    "futureclient","future-client",
    "konas","inertia","exhibition",
    "pandaware","astolfo","rusherhack",
    "novaclient","nova-client","novaware",
    "impactclient","aristois","azura",
    "intentclient","intentstore",
    "prestigeclient",
    "cheatbreaker","kamiblue","fdpclient",
    "skidfuscator","skidware",
    "wolframclient","wolfram-client",
    "bleachhack","bleach-hack",
    "themisclient","ravenb",
    "fluxclient","flux-client",
    "strafeclient","strafe-client"
)

# ══════════════════════════════════════════════════════════════════════════
#  MIXIN SIGNATURES — ONLY class names that are EXCLUSIVE to cheat clients.
#
#  REMOVED (too common in legit Fabric mods):
#    MinecraftMixin, GameRendererMixin, InGameHudMixin, LivingEntityMixin,
#    PlayerEntityMixin, WorldRendererMixin, EntityRenderDispatcherMixin,
#    ClientPlayerEntityMixin, AbstractClientPlayerEntityMixin,
#    LevelRendererMixin, RenderSystemMixin, BufferBuilderMixin,
#    VertexConsumerMixin, HandledScreenMixin, MouseHandlerMixin,
#    KeyboardHandlerMixin, ItemStackMixin
#
#  KEPT: only names that appear exclusively in combat/cheat code and
#  never in popular legit mods.
# ══════════════════════════════════════════════════════════════════════════
$script:cheatMixinSignatures = @(
    # These target combat internals — legit mods never need them
    "MultiPlayerGameModeMixin",
    "ClientPlayerInteractionManagerMixin",
    "CombatTrackerMixin",
    "SwordItemMixin",
    "AxeItemMixin",
    "ShieldItemMixin",
    "EndCrystalEntityMixin",
    "ExplosionMixin",
    "ExplosionMixinAccessor",
    "RespawnAnchorBlockMixin",
    "BedBlockMixin",
    # Anti-cheat bypass mixins — no legit use case
    "MovementInputMixin",
    "ClientConnectionMixin",
    "NetworkHandlerMixin",
    "ChunkDeltaUpdateS2CPacketMixin",
    "PlayerMoveC2SPacketMixin"
)

# ── Refmap names: only flag clearly cheat-named ones.
#    "client" is too generic — many legit mods use it (e.g. morechathistory).
#    REMOVED: "client" from the refmap pattern.
$script:suspiciousRefmapPattern = '"refmap"\s*:\s*"(cheat|hack|phantom|ghost|shadow|xray|aimbot|killaura)[^"]*"'

$script:bytecodeHookSignatures = @(
    "invokeAttackEntity","invokeUseItem","invokeStopUsingItem","callAttackEntity","callUseItem",
    "invokeDoAttack","invokeDoItemUse","invokeOnMouseButton",
    "getAttackCooldownProgress","resetLastAttackedTicks","setItemUseCooldown",
    "setSelectedSlot","setCurrentItem","switchToSlot",
    "setVelocity(0","addVelocity(0","motionX = 0","motionZ = 0",
    "Timer.timerSpeed","setTimerSpeed","timerSpeed","tickLength",
    "cancelPacket","dropPacket","suppressPacket","injectPacket","spoofPacket",
    "sendFakePacket","sendSilentPacket",
    # defineClass only flagged when paired with ClassLoader — handled in bytecode scan
    "VirtualMachine.attach","attachAgent","agentmain","premain"
)

$script:networkExfilSignatures = @(
    "discord.com/api/webhooks","discordapp.com/api/webhooks",
    "sendWebhook","postToWebhook","webhookUrl","WEBHOOK_URL","discordWebhook",
    "grabToken","stealSession","TokenGrabber","SessionStealer","CookieThief",
    "grabify","iplogger.org","2no.co","leakinfo.org","blasze.tk",
    "canarytokens","whereismyip",
    "pastebin.com/raw","hastebin.com/raw","ghostbin.com",
    "api.novaclient.lol","vape.gg/api","intent.store/api","rise.today/api",
    "liquidbounce.net/api","meteordevelopment.org","rusherhack.org/api",
    "exfiltrate","connectBack","callHome","reverseShell","C2Server","c2server",
    "sendToServer(","postData(","uploadData("
)

$deepCheatStrings = @(
    "invokeAttackEntity","invokeUseItem","invokeStopUsingItem","callAttackEntity","callUseItem",
    "getAttackCooldownProgress","resetLastAttackedTicks","ModuleManager","FeatureManager","HackList",
    "CommandManager.register","GuiHacks","ClickGui","AltManager","SessionStealer","spoofPacket",
    "cancelPacket","dropPacket","CPacketHeldItemChange","ServerboundMovePlayerPacket","Timer.timerSpeed",
    "timerSpeed","setTimerSpeed",
    "com.sun.jndi.rmi.object.trustURLCodebase=true","com.sun.jndi.ldap.object.trustURLCodebase=true",
    "-Xrunjdwp:","agentlib:jdwp",
    "dev.gambleclient","xyz.greaj","org.chainlibs","dev.krypton","Dqrkis","dqrkis","lvstrng",
    "Unsafe.getUnsafe",
    "setHardTarget","mixinBypass",
    "defineClass(","VirtualMachine.attach","agentmain(",
    "discord.com/api/webhooks","discordapp.com/api/webhooks",
    "pastebin.com/raw","grabify","iplogger.org",
    "EndCrystalEntityMixin","ExplosionMixinAccessor",
    "ModuleManager","HackManager","CheatManager",
    "toggleModule","isModuleEnabled","getModule(","registerModule(",
    "setTimerSpeed","timerBoost","tickBoost",
    "autocrystal.place","autocrystal.break","crystal.place.delay","crystal.break.delay"
)

# ── REMOVED "fakeVersion" from deep strings — it's a common Mixin accessor
#    method name in legit mods like YACL that override version display for
#    compatibility. Only flag it when combined with other confirmed cheats.

$patternRegex       = [regex]::new('(?<![A-Za-z])(' + (($suspiciousPatterns | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?![A-Za-z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$cheatStringSet     = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $script:cheatStrings) { [void]$cheatStringSet.Add($s) }
$deepCheatStringSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $deepCheatStrings) { [void]$deepCheatStringSet.Add($s) }
$mixinSigSet        = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $script:cheatMixinSignatures) { [void]$mixinSigSet.Add($s) }
$bytecodeSigSet     = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $script:bytecodeHookSignatures) { [void]$bytecodeSigSet.Add($s) }
$networkExfilSet    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
foreach ($s in $script:networkExfilSignatures) { [void]$networkExfilSet.Add($s) }
$fullwidthRegex     = [regex]::new("[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]{2,}", [System.Text.RegularExpressions.RegexOptions]::Compiled)
$tokenRegex         = [regex]::new('(?<![a-z])(' + (($script:knownCheatFileTokens | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')(?![a-z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)

$disallowedMods = @{
    "auto-clicker"                   = @{ Names = @("Auto Clicker","AutoClicker","autoclicker","auto-clicker","Auto-Clicker") }
    "freecam"                        = @{ Names = @("Freecam","freecam","FreeCam","Free Cam") }
    "inventory-profiles-next"        = @{ Names = @("Inventory Profiles Next","InventoryProfilesNext","IPN") }
    "inventory-control-tweaks"       = @{ Names = @("Inventory Control Tweaks","InventoryControlTweaks") }
    "chestcleaner"                   = @{ Names = @("Chest Cleaner","ChestCleaner","chestcleaner") }
    "quickswap"                      = @{ Names = @("QuickSwap","Quick Swap","quickswap") }
    "autofish"                       = @{ Names = @("AutoFish","Auto Fish","autofish","auto-fish") }
    "autofarm"                       = @{ Names = @("AutoFarm","Auto Farm","autofarm") }
    "client-crafting"                = @{ Names = @("Client Crafting","ClientCrafting") }
    "enchant-order"                  = @{ Names = @("Enchant Order","EnchantOrder") }
    "inventory-sorter"               = @{ Names = @("Inventory Sorter","InventorySorter") }
    "shoulder-surfing-reloaded"      = @{ Names = @("Shoulder Surfing","ShoulderSurfing","Shoulder Surfing Reloaded") }
    "camera-utils"                   = @{ Names = @("Camera Utils","CameraUtils") }
    "free-look"                      = @{ Names = @("FreeLook","Free Look","freelook","free-look") }
    "perspective-mod"                = @{ Names = @("Perspective Mod","PerspectiveMod","perspective-mod") }
    "freelook"                       = @{ Names = @("FreeLook","Freelook","free look") }
    "double-hotbar"                  = @{ Names = @("Double Hotbar","DoubleHotbar") }
    "slot-cycler"                    = @{ Names = @("Slot Cycler","SlotCycler") }
    "elytrafly"                      = @{ Names = @("ElytraFly","Elytra Fly","elytrafly") }
    "toggle-sneak-sprint"            = @{ Names = @("Toggle Sneak","Toggle Sprint","ToggleSneak","ToggleSprint") }
    "quick-elytra"                   = @{ Names = @("Quick Elytra","QuickElytra") }
    "sprint-toggle"                  = @{ Names = @("Sprint Toggle","SprintToggle","sprint-toggle") }
    "autosneak"                      = @{ Names = @("AutoSneak","Auto Sneak","autosneak") }
    "stepup"                         = @{ Names = @("StepUp","Step Up","stepup","step-up") }
    "noslow"                         = @{ Names = @("NoSlow","No Slow","noslow","no-slow","NoSlowMod") }
    "bridging-mod"                   = @{ Names = @("Bridging Mod","BridgingMod","SlothPixel") }
    "scaffold"                       = @{ Names = @("Scaffold","scaffold","ScaffoldMod") }
    "tower"                          = @{ Names = @("Tower","TowerMod","tower-mod") }
    "clickcrystals"                  = @{ Names = @("ClickCrystals","clickcrystals","Click Crystals") }
    "walksycrystaloptimizer"         = @{ Names = @("WalksyCrystalOptimizer","WalksyOptimizer","WalskyOptimizer") }
    "hazel-crystal-optimizer"        = @{ Names = @("Hazel Crystal Optimizer","HazelCrystalOptimizer") }
    "switchtotems"                   = @{ Names = @("SwitchTotems","switchtotems","Switch Totems") }
    "no-delay-optimizer"             = @{ Names = @("No Delay Optimizer","NoDelayOptimizer","NoDelay") }
    "dokkos-hotbar-optimizer"        = @{ Names = @("Dokko's Hotbar Optimizer","DokkoHotbar") }
    "crystal-macro"                  = @{ Names = @("Crystal Macro","CrystalMacro","crystal-macro") }
    "anchor-macro"                   = @{ Names = @("Anchor Macro","AnchorMacro","anchor-macro") }
    "totem-macro"                    = @{ Names = @("Totem Macro","TotemMacro","totem-macro") }
    "pot-macro"                      = @{ Names = @("Pot Macro","PotMacro","pot-macro","AutoPotMacro") }
    "combat-macro"                   = @{ Names = @("Combat Macro","CombatMacro","combat-macro") }
    "arrow-shifter"                  = @{ Names = @("Arrow Shifter","ArrowShifter") }
    "d-hand"                         = @{ Names = @("D-hand","Dhand","D Hand") }
    "frostbyte-improved-inventory"   = @{ Names = @("Frostbyte's Improved Inventory","FrostbyteInventory") }
    "fast-xp"                        = @{ Names = @("Fast Xp","FastXP","FastXp") }
    "quick-exp"                      = @{ Names = @("Quick Exp","QuickExp") }
    "xray"                           = @{ Names = @("XRay","xray","X-Ray","x-ray","XRayMod") }
    "cave-finder"                    = @{ Names = @("Cave Finder","CaveFinder","cave-finder") }
    "nofall"                         = @{ Names = @("NoFall","No Fall","nofall","no-fall","NoFallMod") }
    "killaura"                       = @{ Names = @("KillAura","killaura","Kill Aura","kill-aura") }
    "packetmod"                      = @{ Names = @("PacketMod","packet-mod","PacketManipulation") }
    "esp"                            = @{ Names = @("ESP","esp","EspMod","PlayerESP","esp-mod") }
    "speedhack"                      = @{ Names = @("SpeedHack","speedhack","speed-hack","SpeedMod") }
}

# ═════════════════════════════════════════════════════════
#  HELPER FUNCTIONS
# ═════════════════════════════════════════════════════════
function Get-ShannonEntropy { param([byte[]]$Data)
    if ($Data.Length -eq 0) { return 0.0 }
    $freq = @{}; foreach ($b in $Data) { $freq[$b] = ($freq[$b] -as [int]) + 1 }
    $e = 0.0; $len = $Data.Length
    foreach ($c in $freq.Values) { $p = $c / $len; if ($p -gt 0) { $e -= $p * [Math]::Log($p, 2) } }
    return [Math]::Round($e, 4)
}

function Get-Mod-Info-From-Jar { param([string]$jarPath)
    $r = [PSCustomObject]@{ ModId = $null; Name = $null }
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($jarPath)
        foreach ($en in @(
            ($zip.Entries | Where-Object { $_.FullName -match 'fabric\.mod\.json$' } | Select-Object -First 1),
            ($zip.Entries | Where-Object { $_.FullName -match 'quilt\.mod\.json$' }  | Select-Object -First 1)
        )) {
            if (-not $en) { continue }
            try {
                $st = $en.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $j = [System.Text.Encoding]::UTF8.GetString($buf.ToArray()); $buf.Dispose()
                if ($j -match '"id"\s*:\s*"([^"]+)"')   { $r.ModId = $Matches[1] }
                if ($j -match '"name"\s*:\s*"([^"]+)"') { $r.Name  = $Matches[1] }
            } catch {}
        }
        $tomlEntry = $zip.Entries | Where-Object { $_.FullName -match 'META-INF/mods\.toml$' } | Select-Object -First 1
        if ($tomlEntry -and -not $r.ModId) {
            try {
                $st = $tomlEntry.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $t = [System.Text.Encoding]::UTF8.GetString($buf.ToArray()); $buf.Dispose()
                if ($t -match 'modId\s*=\s*"([^"]+)"')       { $r.ModId = $Matches[1] }
                if ($t -match 'displayName\s*=\s*"([^"]+)"') { $r.Name  = $Matches[1] }
            } catch {}
        }
        $zip.Dispose()
    } catch {}
    return $r
}

function Get-MinecraftStatus {
    $mc = $null
    $jp = @(Get-Process javaw -EA 0) + @(Get-Process java -EA 0)
    foreach ($p in $jp) {
        try {
            $w = Get-WmiObject Win32_Process -Filter "ProcessId=$($p.Id)" -EA Stop
            if ($w.CommandLine -match "net\.minecraft|Minecraft") { $mc = $p; break }
        } catch {}
    }
    if ($mc) {
        $up  = (Get-Date) - $mc.StartTime
        $m   = [math]::Floor($up.TotalMinutes)
        $ram = [math]::Round($mc.WorkingSet64 / 1MB, 0)
        return [PSCustomObject]@{ Running = $true; PID = $mc.Id; Uptime = "$m min"; RAM = "$ram MB" }
    }
    return [PSCustomObject]@{ Running = $false; PID = 0; Uptime = "-"; RAM = "-" }
}

# ═════════════════════════════════════════════════════════
#  MIXIN INJECTION SCAN
# ═════════════════════════════════════════════════════════
function Invoke-MixinInjectionScan { param([string]$FilePath, [bool]$IsWhitelisted)
    $hits = [System.Collections.Generic.List[string]]::new()
    if ($IsWhitelisted) { return $hits }
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $mixinJsonEntries = @($zip.Entries | Where-Object { $_.FullName -match '\.mixins\.json$|mixin.*\.json$' })
        foreach ($mje in $mixinJsonEntries) {
            try {
                $st  = $mje.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $txt = [System.Text.Encoding]::UTF8.GetString($buf.ToArray()); $buf.Dispose()
                # Threshold raised to 200 — Fabric API has 300+ mixins
                $mixinMatches = [regex]::Matches($txt, '"[A-Za-z][A-Za-z0-9_$]+"')
                if ($mixinMatches.Count -gt 200) { $hits.Add("Excessive mixin count ($($mixinMatches.Count)) in $($mje.FullName) — typical of cheat clients") }
                foreach ($sig in $mixinSigSet) {
                    if ($txt -match [regex]::Escape($sig)) { $hits.Add("Cheat mixin target: $sig") }
                }
                # Only flag refmap names that are explicitly cheat-themed (not generic "client")
                if ($txt -match $script:suspiciousRefmapPattern) {
                    $hits.Add("Suspicious refmap name: $($Matches[1])")
                }
            } catch {}
        }
        $classEntries = @($zip.Entries | Where-Object { $_.FullName -match '\.class$' } | Select-Object -First 50)
        foreach ($ce in $classEntries) {
            try {
                $st  = $ce.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $raw = $buf.ToArray(); $buf.Dispose()
                $a   = [System.Text.Encoding]::ASCII.GetString($raw)
                foreach ($sig in $mixinSigSet) {
                    if ($a.Contains($sig)) { $hits.Add("Mixin bytecode hit: $sig"); break }
                }
            } catch {}
        }
        $zip.Dispose()
    } catch {}
    return $hits
}

# ═════════════════════════════════════════════════════════
#  BYTECODE HOOK SCAN
# ═════════════════════════════════════════════════════════
function Invoke-BytecodeHookScan { param([string]$FilePath, [bool]$IsWhitelisted)
    $hits = [System.Collections.Generic.List[string]]::new()
    if ($IsWhitelisted) { return $hits }
    try {
        $zip     = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $classes = @($zip.Entries | Where-Object { $_.FullName -match '\.class$' })
        $sampled = $classes | Select-Object -First ([math]::Min(60, $classes.Count))
        foreach ($ce in $sampled) {
            try {
                $st  = $ce.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $raw = $buf.ToArray(); $buf.Dispose()
                $a   = [System.Text.Encoding]::ASCII.GetString($raw)
                foreach ($sig in $bytecodeSigSet) {
                    if ($a.Contains($sig)) { $hits.Add("Bytecode hook: $sig"); break }
                }
                # Only flag defineClass when explicitly combined with ClassLoader (dynamic injection)
                if ($a -match 'defineClass' -and $a -match 'ClassLoader' -and $a -notmatch 'SecureClassLoader|URLClassLoader') {
                    $hits.Add("Dynamic class injection detected")
                }
            } catch {}
        }
        $zip.Dispose()
    } catch {}
    $unique = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($h in $hits) { [void]$unique.Add($h) }
    return [System.Collections.Generic.List[string]]$unique
}

# ═════════════════════════════════════════════════════════
#  NETWORK EXFILTRATION SCAN
# ═════════════════════════════════════════════════════════
function Invoke-NetworkExfilScan { param([string]$FilePath, [bool]$IsWhitelisted)
    $hits = [System.Collections.Generic.List[string]]::new()
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $scanExt = '\.(class|json|toml|yml|yaml|txt|cfg|properties|xml|html|js|kt|groovy)$|MANIFEST\.MF'
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -notmatch $scanExt) { continue }
            try {
                $st  = $entry.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $raw = $buf.ToArray(); $buf.Dispose()
                $a   = [System.Text.Encoding]::ASCII.GetString($raw)
                $u   = [System.Text.Encoding]::UTF8.GetString($raw)
                foreach ($sig in $networkExfilSet) {
                    if ($a.Contains($sig) -or $u.Contains($sig)) {
                        $hits.Add("Network exfil: $sig"); break
                    }
                }
            } catch {}
        }
        $zip.Dispose()
    } catch {}
    $unique = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($h in $hits) { [void]$unique.Add($h) }
    return [System.Collections.Generic.List[string]]$unique
}

# ═════════════════════════════════════════════════════════
#  ENHANCED OBFUSCATION SCAN
# ═════════════════════════════════════════════════════════
function Invoke-ObfuscationFlags { param([string]$FilePath)
    $flags = [System.Collections.Generic.List[string]]::new()
    $baseName = Get-ModBaseName -FileName ([System.IO.Path]::GetFileName($FilePath))
    $isWhitelisted = $script:cleanModWhitelist.Contains($baseName)
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($FilePath)
        $modInfo    = Get-Mod-Info-From-Jar -jarPath $FilePath
        $outerModId = $modInfo.ModId
        if ($outerModId -and $script:cleanModWhitelist.Contains($outerModId)) { $isWhitelisted = $true }
        $classes    = @($zip.Entries | Where-Object { $_.FullName -match '\.class$' })
        $totalClassCount = $classes.Count
        if ($totalClassCount -eq 0) { $zip.Dispose(); return $flags }

        $obfuscatedCount = 0; $numericClassCount = 0; $unicodeClassCount = 0
        foreach ($c in $classes) {
            $parts = $c.FullName.Split('/')
            $isObf = ($parts[0..($parts.Count - 2)] | Where-Object { $_.Length -le 1 -and $_ -cmatch '^[a-z]$' }).Count -ge 2
            if ($isObf) { $obfuscatedCount++ }
            $cn = [System.IO.Path]::GetFileNameWithoutExtension($c.Name)
            if ($cn -cmatch '^\d+$')          { $numericClassCount++ }
            if ($cn -match '[^\x00-\x7F]')    { $unicodeClassCount++ }
        }

        $obfPct = if ($totalClassCount -ge 10) { [math]::Round(($obfuscatedCount / $totalClassCount) * 100) } else { 0 }
        $numPct = if ($totalClassCount -ge 5)  { [math]::Round(($numericClassCount / $totalClassCount) * 100) } else { 0 }
        $uniPct = if ($totalClassCount -ge 5)  { [math]::Round(($unicodeClassCount / $totalClassCount) * 100) } else { 0 }

        $runtimeExecFound = $false; $httpDownloadFound = $false; $httpExfilFound = $false
        $sampled = $classes | Select-Object -First ([math]::Min(30, $totalClassCount))
        foreach ($ce in $sampled) {
            try {
                $st = $ce.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $raw = $buf.ToArray(); $buf.Dispose()
                $a = [System.Text.Encoding]::ASCII.GetString($raw)
                if ($a -match 'Runtime\.exec')              { $runtimeExecFound  = $true }
                if ($a -match 'openConnection|getOutputStream') { $httpDownloadFound = $true }
                if ($a -match 'setRequestMethod.*POST')     { $httpExfilFound    = $true }
            } catch {}
        }

        if (-not $isWhitelisted) {
            if ($runtimeExecFound -and $obfPct -ge 25) { $flags.Add("Runtime.exec() in obfuscated code — can run arbitrary OS commands") }
            if ($httpDownloadFound -and $obfPct -ge 20) { $flags.Add("HTTP file download in obfuscated code — fetches files from remote server at runtime") }
            if ($httpExfilFound)                        { $flags.Add("HTTP POST exfiltration — sends system data to an external server") }
        }
        if ($totalClassCount -ge 10 -and $obfPct -ge 25) { $flags.Add("Heavy obfuscation — $obfPct% of classes use single-letter path segments") }
        if ($numPct -ge 20) { $flags.Add("Numeric class names — $numPct% of classes have numeric-only names") }
        if ($uniPct -ge 10) { $flags.Add("Unicode class names — $uniPct% of classes use non-ASCII characters") }

        $knownLegitModIds = @("vmp-fabric","vmp","lithium","sodium","iris","fabric-api","modmenu","ferrite-core",
            "lazydfu","starlight","entityculling","memoryleakfix","krypton","c2me-fabric","smoothboot-fabric",
            "immediatelyfast","noisium","threadtweak","indium","rendervis","entity_texture_features",
            "citresewn","sodium-extra","rei","jei","journeymap","xaerominimap","xaeroworldmap","lithium",
            "phosphor","appleskin","modelfix","dynamic-fps","betterthirdperson","fpsreducer",
            "motionblur","ravenclawspingequalizer","silicon","creamykeys","carpet","malilib")
        $dangerCount = ($flags | Where-Object { $_ -match "Runtime\.exec|HTTP file download|HTTP POST|Heavy obfuscation" }).Count
        if ($outerModId -and ($knownLegitModIds -contains $outerModId) -and $dangerCount -gt 0) {
            $flags.Add("Fake mod identity — claims to be '$outerModId' but contains dangerous code")
        }

        $obfuscatorSigs = @{
            "Allatori"     = "Allatori"
            "Zelix"        = "Zelix"
            "ProGuard"     = "Obfuscated-By: ProGuard"
            "Stringer"     = "Stringer Java Obfuscator"
            "Skidfuscator" = "skidfuscator"
            "Radon"        = "Obfuscated-By: Radon"
            "BisGuard"     = "BisGuard"
            "Paramorphism" = "paramorphism"
        }
        foreach ($entry in ($zip.Entries | Where-Object { $_.FullName -match 'MANIFEST\.MF$|\.json$|\.toml$' })) {
            try {
                $st = $entry.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $txt = [System.Text.Encoding]::UTF8.GetString($buf.ToArray()); $buf.Dispose()
                foreach ($kv in $obfuscatorSigs.GetEnumerator()) {
                    if ($txt -match [regex]::Escape($kv.Value)) { $flags.Add("Obfuscator marker: $($kv.Key)") }
                }
            } catch {}
        }

        $encMarkers = @("decrypt","deobf","StringEncryption","StringDecryptor","decryptString","stringPool","StringPool")
        $encCount = 0
        foreach ($ce in ($classes | Select-Object -First 20)) {
            try {
                $st = $ce.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $a = [System.Text.Encoding]::ASCII.GetString($buf.ToArray()); $buf.Dispose()
                foreach ($m in $encMarkers) { if ($a -match $m) { $encCount++; break } }
            } catch {}
        }
        if ($encCount -ge 5) { $flags.Add("String encryption detected in $encCount class(es)") }

        $zip.Dispose()
    } catch {}
    return $flags
}

# ═════════════════════════════════════════════════════════
#  MOD SIGNATURE SCAN
# ═════════════════════════════════════════════════════════
function Get-ModSignature { param([string]$Path, [bool]$ScanStrings = $true, [bool]$ScanDeep = $true)
    $hits = [System.Collections.Generic.HashSet[string]]::new()
    $entropyWarnings = [System.Collections.Generic.List[string]]::new()

    $baseName      = Get-ModBaseName -FileName ([System.IO.Path]::GetFileName($Path))
    $isWhitelisted = $script:cleanModWhitelist.Contains($baseName)

    try {
        $zip  = [System.IO.Compression.ZipFile]::OpenRead($Path)
        $mi = Get-Mod-Info-From-Jar -jarPath $Path
        if ($mi.ModId -and $script:cleanModWhitelist.Contains($mi.ModId)) { $isWhitelisted = $true }

        foreach ($e in $zip.Entries) {
            foreach ($m in $patternRegex.Matches($e.FullName)) { [void]$hits.Add("P|$($m.Value)") }
        }
        $flat   = [System.Collections.Generic.List[object]]::new()
        $nested = [System.Collections.Generic.List[object]]::new()
        foreach ($e in $zip.Entries) { $flat.Add($e) }
        foreach ($nj in ($zip.Entries | Where-Object { $_.FullName -match "^META-INF/jars/.+\.jar$" })) {
            try {
                $ns = $nj.Open(); $ms = New-Object System.IO.MemoryStream; $ns.CopyTo($ms); $ns.Close(); $ms.Position = 0
                $iz = [System.IO.Compression.ZipArchive]::new($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $nested.Add($iz); foreach ($ie in $iz.Entries) { $flat.Add($ie) }
            } catch {}
        }
        $scanExt = '\.(class|json|toml|yml|yaml|txt|cfg|properties|xml|html|js|ts|kt|groovy)$|MANIFEST\.MF'
        foreach ($entry in $flat) {
            if ($entry.FullName -notmatch $scanExt) { continue }
            try {
                $st  = $entry.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                $raw = $buf.ToArray(); $buf.Dispose()
                $a   = [System.Text.Encoding]::ASCII.GetString($raw)
                $u   = [System.Text.Encoding]::UTF8.GetString($raw)
                foreach ($m in $patternRegex.Matches($a)) { [void]$hits.Add("P|$($m.Value)") }
                if ($ScanStrings -and -not $isWhitelisted) {
                    foreach ($cs in $cheatStringSet) {
                        if ($script:contextOnlyStrings.Contains($cs)) { continue }
                        if ($a.Contains($cs) -or $u.Contains($cs)) { [void]$hits.Add("S|$cs") }
                    }
                    foreach ($m in $fullwidthRegex.Matches($u)) { [void]$hits.Add("F|$($m.Value)") }
                }
                if ($ScanDeep -and -not $isWhitelisted) {
                    foreach ($ds in $deepCheatStringSet) {
                        if ($script:contextOnlyStrings.Contains($ds)) { continue }
                        if ($a.Contains($ds) -or $u.Contains($ds)) { [void]$hits.Add("D|$ds") }
                    }
                    if ($entry.FullName -match '\.class$' -and $raw.Length -gt 512) {
                        $ent = Get-ShannonEntropy -Data $raw
                        if ($ent -gt 7.2) {
                            $sn = [System.IO.Path]::GetFileName($entry.FullName)
                            $entropyWarnings.Add("HIGH_ENTROPY:$sn($ent)")
                        }
                    }
                }
            } catch {}
        }
        foreach ($n in $nested) { try { $n.Dispose() } catch {} }
        $zip.Dispose()
    } catch {}

    $fwPool = @($script:cheatStrings | Where-Object { $_ -cmatch "[\uFF21-\uFF3A\uFF41-\uFF5A\uFF10-\uFF19]" })
    foreach ($h in @($hits)) {
        if ($h -match '^F\|') {
            $fw   = $h.Substring(2); if ($fw.Length -lt 3) { continue }
            $best = $null
            foreach ($cs in $fwPool) { if ($cs.Contains($fw)) { if ($null -eq $best -or $cs.Length -lt $best.Length) { $best = $cs } } }
            $final = if ($best) { $best } elseif ($fw.Length -ge 6) { $fw } else { $null }
            if ($final) { $hits.Remove($h); [void]$hits.Add("F|$final") }
        }
    }
    $fwFinal  = @($hits | Where-Object { $_ -match '^F\|' } | ForEach-Object { $_.Substring(2) })
    $fwUnique = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($fw in $fwFinal) {
        $red = $false
        foreach ($other in $fwFinal) { if ($fw.Length -lt $other.Length -and $other.Contains($fw)) { $red = $true; break } }
        if (-not $red) { [void]$fwUnique.Add($fw) }
    }
    $cleaned = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($h in $hits) {
        if ($h -match '^F\|') { if ($fwUnique.Contains($h.Substring(2))) { [void]$cleaned.Add($h) } }
        else { [void]$cleaned.Add($h) }
    }
    foreach ($ew in $entropyWarnings) { [void]$cleaned.Add("E|$ew") }
    return $cleaned
}

function Get-ModSources { param([string]$Path)
    $urls = [System.Collections.Generic.List[string]]::new()
    $bl   = @("w3\.org","jsonschema\.org","fabricmc\.net","quiltmc\.net","oracle\.com","mojang\.com","minecraft\.net","isxander\.dev","github\.com")
    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($Path)
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName -match '\.(json|toml|yml|yaml)$|MANIFEST\.MF') {
                try {
                    $st  = $entry.Open(); $buf = New-Object System.IO.MemoryStream; $st.CopyTo($buf); $st.Close()
                    $raw = [System.Text.Encoding]::UTF8.GetString($buf.ToArray()); $buf.Dispose()
                    $rm  = [regex]::Matches($raw, "https?://[^\s<>]+")
                    foreach ($m in $rm) {
                        $url   = $m.Value.TrimEnd('\', ',', ')', '}', '"')
                        $isBl  = $false
                        foreach ($b in $bl) { if ($url -match $b) { $isBl = $true; break } }
                        if (-not $isBl -and $url -notmatch '\.(png|jpg|jpeg|gif|svg)$') { $urls.Add($url) }
                    }
                } catch {}
            }
        }
        $zip.Dispose()
    } catch {}
    return @($urls | Select-Object -Unique)
}

function Find-DisallowedMods { param([string]$Path, [array]$JarFiles)
    $found = [System.Collections.Generic.List[PSObject]]::new()
    foreach ($file in $JarFiles) {
        $fn = $file.Name.ToLower()
        $mi = Get-Mod-Info-From-Jar -jarPath $file.FullName
        $baseName = Get-ModBaseName -FileName $file.Name
        if ($script:cleanModWhitelist.Contains($baseName)) { continue }
        if ($mi.ModId -and $script:cleanModWhitelist.Contains($mi.ModId)) { continue }
        foreach ($slug in $disallowedMods.Keys) {
            $md     = $disallowedMods[$slug]
            $isDis  = $false; $src = ""
            if ($mi.ModId -and $mi.ModId.ToLower() -match [regex]::Escape($slug.ToLower()))                            { $isDis = $true; $src = "mod ID" }
            elseif ($mi.Name -and $mi.Name.ToLower() -match [regex]::Escape($slug.ToLower().Replace('-', ' ')))        { $isDis = $true; $src = "mod name" }
            else {
                foreach ($name in $md.Names) {
                    $nl = $name.ToLower(); $ns = $nl -replace '\s', ''; $sl = $slug.ToLower()
                    if ($fn -eq "$nl.jar" -or $fn -eq "$ns.jar" -or $fn -eq "$sl.jar" -or $fn -match [regex]::Escape($ns)) {
                        $isDis = $true; $src = "filename"; break
                    }
                }
            }
            if ($isDis) {
                $found.Add([PSCustomObject]@{
                    FileName    = $file.Name
                    ModName     = $md.Names[0]
                    Slug        = $slug
                    MatchedBy   = $src
                    DetectedId  = if ($mi.ModId) { $mi.ModId } else { "-" }
                    DetectedName = if ($mi.Name)  { $mi.Name }  else { "-" }
                }); break
            }
        }
    }
    return $found
}

# ═════════════════════════════════════════════════════════
#  JVM ARGUMENT SCANNER
# ═════════════════════════════════════════════════════════
function Test-JvmArguments {
    $findings   = [System.Collections.Generic.List[PSObject]]::new()
    $foundFlags = [System.Collections.Generic.HashSet[string]]::new()
    $javaProcs  = @(Get-Process javaw -EA 0) + @(Get-Process java -EA 0)
    if ($javaProcs.Count -eq 0) { return $findings }

    $suspiciousArgsList = @(
        @('-Dfabric\.addMods=',                  'FABRIC_ADD_MODS',              'HIGH',   'Injects extra Fabric mod JARs at runtime'),
        @('-Dfabric\.loadMods=',                 'FABRIC_LOAD_MODS',             'HIGH',   'Overrides Fabric mod loading mechanism'),
        @('-Dfabric\.classPathGroups=',          'FABRIC_CLASSPATH_GROUPS',      'HIGH',   'Manipulates Fabric classpath groups'),
        @('-Dfabric\.gameJarPath=',              'FABRIC_GAME_JAR_PATH',         'MEDIUM', 'Redirects Minecraft game JAR path'),
        @('-Dfabric\.skipMcProvider=',           'FABRIC_SKIP_MC_PROVIDER',      'HIGH',   'Skips Minecraft provider checks'),
        @('-Dfabric\.remapClasspathFile=',       'FABRIC_REMAP_CLASSPATH',       'HIGH',   'Redirects remap classpath file'),
        @('-Dfabric\.skipIntermediary=',         'FABRIC_SKIP_INTERMEDIARY',     'HIGH',   'Skips intermediary mappings'),
        @('-Dfabric\.mixin\.configs=',           'FABRIC_MIXIN_CONFIGS',         'HIGH',   'Injects custom Mixin configs'),
        @('-Dfabric\.mixin\.hotSwap=',           'FABRIC_MIXIN_HOTSWAP',         'HIGH',   'Enables Mixin hot-swapping (runtime code injection)'),
        @('-Dfabric\.forceVersion=',             'FABRIC_FORCE_VERSION',         'HIGH',   'Forces a specific game version'),
        @('-Dfabric\.customModList=',            'FABRIC_CUSTOM_MOD_LIST',       'HIGH',   'Injects custom mod list'),
        @('-Dfabric\.skipDependencyResolution=', 'FABRIC_SKIP_DEP_RESOLUTION',   'HIGH',   'Skips dependency resolution'),
        @('-Dfabric\.loader\.entrypoints=',      'FABRIC_LOADER_ENTRYPOINTS',    'HIGH',   'Injects custom entrypoints'),
        @('-Dfabric\.language\.providers=',      'FABRIC_LANGUAGE_PROVIDERS',    'HIGH',   'Injects custom language providers'),
        @('-Dfabric\.mods\.toml\.path=',         'FABRIC_MODS_TOML_PATH',        'HIGH',   'Redirects Fabric mods.toml path'),
        @('-Dfabric\.resolve\.modFiles=',        'FABRIC_RESOLVE_MODFILES',      'MEDIUM', 'Forces mod file resolution'),
        @('-Dfabric\.loader\.config=',           'FABRIC_LOADER_CONFIG',         'MEDIUM', 'Redirects Fabric loader config'),
        @('-Dfabric\.configDir=',                'FABRIC_CONFIG_DIR',            'MEDIUM', 'Changes Fabric config directory'),
        @('-Dfabric\.gameVersion=',              'FABRIC_GAME_VERSION',          'MEDIUM', 'Overrides Fabric game version'),
        @('-Dfabric\.allowUnsupportedVersion=',  'FABRIC_UNSUPPORTED_VERSION',   'MEDIUM', 'Allows unsupported Minecraft versions'),
        @('-Dfabric\.dli\.config=',              'FABRIC_DLI_CONFIG',            'MEDIUM', 'Changes data loader injector config'),
        @('-Dfabric\.development=',              'FABRIC_DEV_MODE',              'LOW',    'Enables Fabric development mode'),
        @('-Dforge\.addMods=',                   'FORGE_ADD_MODS',               'HIGH',   'Injects extra Forge mod JARs at runtime'),
        @('-Dforge\.mods=',                      'FORGE_MODS',                   'HIGH',   'Overrides Forge mod list'),
        @('-Dfml\.coreMods\.load=',              'FORGE_COREMODS',               'HIGH',   'Loads Forge core mods via JVM flag'),
        @('-Dforge\.coreMods\.dir=',             'FORGE_COREMODS_DIR',           'HIGH',   'Redirects core mods directory'),
        @('-Dforge\.modDir=',                    'FORGE_MOD_DIR',                'HIGH',   'Redirects mod directory'),
        @('-Dforge\.modsDirectories=',           'FORGE_MODS_DIRECTORIES',       'HIGH',   'Adds extra mod directories'),
        @('-Dfml\.customModList=',               'FORGE_CUSTOM_MOD_LIST',        'HIGH',   'Injects custom Forge mod list'),
        @('-Dforge\.disableModScan=',            'FORGE_DISABLE_MODSCAN',        'HIGH',   'Disables Forge mod scanning'),
        @('-Dforge\.modList=',                   'FORGE_MOD_LIST',               'HIGH',   'Overrides Forge mod list'),
        @('-Dforge\.mixin\.hotSwap=',            'FORGE_MIXIN_HOTSWAP',          'HIGH',   'Enables Forge Mixin hot-swapping'),
        @('-Dforge\.forceVersion=',              'FORGE_FORCE_VERSION',          'HIGH',   'Forces Forge version'),
        @('-Dforge\.disableUpdateCheck=',        'FORGE_DISABLE_UPDATE',         'MEDIUM', 'Disables Forge update checks'),
        @('-Djava\.security\.manager=',          'SECURITY_MANAGER_DISABLED',    'HIGH',   'Disables Java Security Manager'),
        @('-Djava\.security\.policy=',           'SECURITY_POLICY_OVERRIDE',     'HIGH',   'Overrides security policy (permissions bypass)'),
        @('-Xbootclasspath',                     'BOOTCLASSPATH_MODIFY',         'HIGH',   'Modifies boot classpath (critical system classes)'),
        @('-Djava\.system\.class\.loader=',      'CUSTOM_CLASSLOADER',           'HIGH',   'Replaces system classloader'),
        @('-Djava\.class\.path=',                'CLASSPATH_OVERRIDE',           'HIGH',   'Overrides Java classpath'),
        @('-cp\s+[^ ].*\.jar',                   'CLASSPATH_JAR_INJECTION',      'HIGH',   'Injects JAR via -cp classpath flag'),
        @('-Xrunjdwp:',                          'REMOTE_DEBUG',                 'HIGH',   'Remote debugging enabled (possible RCE)'),
        @('agentlib:jdwp',                       'JDWP_AGENT',                   'HIGH',   'JDWP agent attached — debugger can execute arbitrary code'),
        @('-agentlib:',                          'NATIVE_AGENT',                 'HIGH',   'Loads native JVMTI agent'),
        @('-agentpath:',                         'NATIVE_AGENT_PATH',            'HIGH',   'Loads native agent by path'),
        @('-D(client|launcher)\.brand=(Wurst|Aristois|Impact|Future|Lambda|Rusher|Konas|Phobos|Salhack|Meteor|Async|Wolfram|Huzuni|Rise|Flux|Gamesense|Intent|Remix|Vape|Ghost|Inertia|Sigma|Novoline|Ares|Prestige|Entropy)',
          'CHEAT_CLIENT_BRAND', 'HIGH', 'Cheat client brand spoofed in JVM arguments')
    )

    $agentWhitelist = @("jmxremote","yjp","jrebel","newrelic","jacoco","hotswapagent","theseus","lunar","appney")

    foreach ($javaProc in $javaProcs) {
        $javaPid = $javaProc.Id
        try {
            $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $javaPid" -EA Stop
            $cmd = $wmi.CommandLine
            if (-not $cmd -or -not ($cmd -match "net\.minecraft|Minecraft")) { continue }

            $agentMatches = [regex]::Matches($cmd, '-javaagent:([^\s"]+)')
            foreach ($m in $agentMatches) {
                $agPath = $m.Groups[1].Value.Trim('"').Trim("'")
                $agName = [System.IO.Path]::GetFileName($agPath)
                $safe   = $false
                foreach ($w in $agentWhitelist) { if ($agName -match $w) { $safe = $true; break } }
                if (-not $safe) {
                    $key = "AGENT|$agName"
                    if ($foundFlags.Add($key)) {
                        $findings.Add([PSCustomObject]@{ Type = "JAVA_AGENT"; Detail = "Untrusted javaagent loaded: $agName"; Severity = "HIGH"; PID = $javaPid })
                    }
                }
            }

            foreach ($sf in $suspiciousArgsList) {
                if ($cmd -match $sf[0]) {
                    $key = "$($sf[1])|$javaPid"
                    if ($foundFlags.Add($key)) {
                        $findings.Add([PSCustomObject]@{ Type = $sf[1]; Detail = $sf[3]; Severity = $sf[2]; PID = $javaPid })
                    }
                }
            }

            if ($cmd -match '(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)') {
                $key = "URL_ENCODE|$javaPid"
                if ($foundFlags.Add($key)) {
                    $findings.Add([PSCustomObject]@{ Type = "ENCODED_INJECTION"; Detail = "URL-encoded shell metacharacters in JVM args — possible command injection"; Severity = "HIGH"; PID = $javaPid })
                }
            }

            try {
                $netConn = Get-NetTCPConnection -OwningProcess $javaPid -EA Stop |
                    Where-Object { $_.LocalAddress -eq '127.0.0.1' -and $_.State -eq 'Listen' }
                if ($netConn) {
                    $ports = $netConn.LocalPort -join ', '
                    $key   = "LOCAL_LISTEN|$javaPid"
                    if ($foundFlags.Add($key)) {
                        $findings.Add([PSCustomObject]@{ Type = "LOCAL_LISTEN"; Detail = "Java opened server socket(s) on port(s): $ports — vanilla MC never listens"; Severity = "HIGH"; PID = $javaPid })
                    }
                }
            } catch {}

        } catch {}
    }
    return $findings
}

# ═════════════════════════════════════════════════════════
#  REPORT HELPERS
# ═════════════════════════════════════════════════════════
$W = 72
function Write-Border { param([string]$Type, [System.ConsoleColor]$Color)
    switch ($Type) {
        'top' { Write-Host ("  ╔" + ("═" * $W) + "╗") -ForegroundColor $Color }
        'sep' { Write-Host ("  ╠" + ("═" * $W) + "╣") -ForegroundColor $Color }
        'bot' { Write-Host ("  ╚" + ("═" * $W) + "╝") -ForegroundColor $Color }
    }
}
function Write-Row { param([string]$Label, [string]$Value,
    [System.ConsoleColor]$LabelColor = [System.ConsoleColor]::DarkGray,
    [System.ConsoleColor]$ValueColor = [System.ConsoleColor]::White,
    [System.ConsoleColor]$BC         = [System.ConsoleColor]::DarkGray)
    $avail = $W - $Label.Length
    if ($avail -lt 4) {
        $tl = $Label.Substring(0, [math]::Max(0, $W - 4)); $p = $W - $tl.Length
        Write-Host "  ║" -ForegroundColor $BC -NoNewline
        Write-Host $tl   -ForegroundColor $LabelColor -NoNewline
        Write-Host (" " * [math]::Max(0, $p) + "║") -ForegroundColor $BC; return
    }
    if ($Value.Length -gt $avail - 3) { $Value = $Value.Substring(0, [math]::Max(0, $avail - 4)) + "..." }
    $p = [math]::Max(0, $W - $Label.Length - $Value.Length)
    Write-Host "  ║"   -ForegroundColor $BC -NoNewline
    Write-Host $Label  -ForegroundColor $LabelColor -NoNewline
    Write-Host $Value  -ForegroundColor $ValueColor -NoNewline
    Write-Host (" " * $p + "║") -ForegroundColor $BC
}
function Write-RowFull { param([string]$Text,
    [System.ConsoleColor]$TC = [System.ConsoleColor]::White,
    [System.ConsoleColor]$BC = [System.ConsoleColor]::DarkGray)
    if ($Text.Length -gt $W - 3) { $Text = $Text.Substring(0, [math]::Max(0, $W - 4)) + "..." }
    $p = [math]::Max(0, $W - $Text.Length)
    Write-Host "  ║"  -ForegroundColor $BC -NoNewline
    Write-Host $Text  -ForegroundColor $TC -NoNewline
    Write-Host (" " * $p + "║") -ForegroundColor $BC
}

# ═════════════════════════════════════════════════════════
#  MAIN SCAN
# ═════════════════════════════════════════════════════════
try { $jars = Get-ChildItem -Path $modsPath -Filter *.jar -EA Stop } catch {
    Write-Host "  Cannot read directory." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 1
}
if ($jars.Count -eq 0) {
    Write-Host "  No JAR files found." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit 0
}

$scanTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$mcStatus      = Get-MinecraftStatus

Write-Host ""
Write-Host "  $scanTimestamp" -ForegroundColor DarkGray
Write-Host "  $modsPath"      -ForegroundColor DarkGray
Write-Host "  $($jars.Count) file(s) found" -ForegroundColor DarkGray
Write-Host ""
if ($mcStatus.Running) {
    Write-Host "  Minecraft  " -ForegroundColor DarkGray -NoNewline
    Write-Host "● " -ForegroundColor Magenta -NoNewline
    Write-Host "Running  " -ForegroundColor White -NoNewline
    Write-Host "PID $($mcStatus.PID)   $($mcStatus.Uptime)   $($mcStatus.RAM) RAM" -ForegroundColor DarkGray
} else {
    Write-Host "  Minecraft  " -ForegroundColor DarkGray -NoNewline
    Write-Host "○ " -ForegroundColor DarkGray -NoNewline
    Write-Host "Not running" -ForegroundColor DarkGray
}

# ── Phase 1: JVM Argument Scan
Write-Host ""
Write-Host "  ┌─ " -ForegroundColor DarkMagenta -NoNewline
Write-Host "Phase 1" -ForegroundColor Magenta -NoNewline
Write-Host " · JVM Argument Injection Detection" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkMagenta
Write-Host "  │  scanning... " -ForegroundColor DarkGray -NoNewline
$jvmResults = Test-JvmArguments
if ($jvmResults.Count -gt 0) {
    $jvmHigh = @($jvmResults | Where-Object { $_.Severity -eq "HIGH" }).Count
    $jvmMed  = @($jvmResults | Where-Object { $_.Severity -eq "MEDIUM" }).Count
    $parts   = @(); if ($jvmHigh -gt 0) { $parts += "$jvmHigh HIGH" }; if ($jvmMed -gt 0) { $parts += "$jvmMed MEDIUM" }
    Write-Host "$($jvmResults.Count) issue(s) ($($parts -join ', '))" -ForegroundColor Red
} else { Write-Host "clean" -ForegroundColor Cyan }
Write-Host "  └─ done" -ForegroundColor DarkMagenta

# ── Phase 2: String Analysis + Deep Scan + Filename Tokens
$total   = $jars.Count; $i = 0
$flagged = [System.Collections.Generic.List[PSObject]]::new()
$clean   = [System.Collections.Generic.List[string]]::new()
Write-Host ""
Write-Host "  ┌─ " -ForegroundColor DarkMagenta -NoNewline
Write-Host "Phase 2" -ForegroundColor Magenta -NoNewline
Write-Host " · String Analysis + Deep Scan + Filename Tokens" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkMagenta
foreach ($jar in $jars) {
    $i++; $pct  = [math]::Floor(($i / $total) * 100)
    $padN = $jar.Name.PadRight(40).Substring(0, [math]::Min(40, $jar.Name.Length))
    [Console]::Write("  │  $pct% $padN`r")
    $baseName      = Get-ModBaseName -FileName $jar.Name
    $isWhitelisted = $script:cleanModWhitelist.Contains($baseName)
    # Also check mod ID
    $mi2 = Get-Mod-Info-From-Jar -jarPath $jar.FullName
    if ($mi2.ModId -and $script:cleanModWhitelist.Contains($mi2.ModId)) { $isWhitelisted = $true }
    $sig     = Get-ModSignature -Path $jar.FullName -ScanStrings $true -ScanDeep $true
    $fnMatch = if (-not $isWhitelisted) { $tokenRegex.Match($jar.Name.ToLower()) } else { [System.Text.RegularExpressions.Match]::Empty }
    if ($sig.Count -gt 0 -or $fnMatch.Success) {
        $pats   = @($sig | Where-Object { $_ -match '^P\|' } | ForEach-Object { $_.Substring(2) })
        $strs   = @($sig | Where-Object { $_ -match '^S\|' } | ForEach-Object { $_.Substring(2) })
        $fws    = @($sig | Where-Object { $_ -match '^F\|' } | ForEach-Object { $_.Substring(2) })
        $deep_s = @($sig | Where-Object { $_ -match '^D\|' } | ForEach-Object { $_.Substring(2) })
        $entrp  = @($sig | Where-Object { $_ -match '^E\|' } | ForEach-Object { $_.Substring(2) })
        $sources = Get-ModSources -Path $jar.FullName
        $flagged.Add([PSCustomObject]@{
            Name          = $jar.Name
            Path          = $jar.FullName
            Size          = [math]::Round($jar.Length / 1KB, 1)
            Patterns      = $pats
            Strings       = $strs
            Fullwidth     = $fws
            DeepHits      = $deep_s
            Entropy       = $entrp
            HitCount      = $sig.Count
            Sources       = $sources
            ObfResult     = $null
            MixinHits     = $null
            BytecodeHits  = $null
            NetworkHits   = $null
            FilenameToken = if ($fnMatch.Success) { $fnMatch.Value } else { $null }
            IsWhitelisted = $isWhitelisted
        })
    } else { $clean.Add($jar.Name) }
}
Write-Host "  │  100% done                                      " -ForegroundColor DarkMagenta
Write-Host "  └─ $($flagged.Count) flagged  /  $($clean.Count) clean" -ForegroundColor DarkMagenta

# ── Phase 3: Advanced Obfuscation Detection
Write-Host ""
Write-Host "  ┌─ " -ForegroundColor DarkMagenta -NoNewline
Write-Host "Phase 3" -ForegroundColor Magenta -NoNewline
Write-Host " · Advanced Obfuscation Detection" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkMagenta
$oi = 0
foreach ($jar in $jars) {
    $oi++; $pct  = [math]::Floor(($oi / $total) * 100)
    $padN = $jar.Name.PadRight(40).Substring(0, [math]::Min(40, $jar.Name.Length))
    [Console]::Write("  │  $pct% $padN`r")
    $oFlags   = Invoke-ObfuscationFlags -FilePath $jar.FullName
    $existing = $flagged | Where-Object { $_.Name -eq $jar.Name } | Select-Object -First 1
    if ($existing)          { $existing.ObfResult = $oFlags }
    elseif ($oFlags.Count -gt 0) {
        $baseName = Get-ModBaseName -FileName $jar.Name
        $flagged.Add([PSCustomObject]@{
            Name = $jar.Name; Path = $jar.FullName; Size = [math]::Round($jar.Length / 1KB, 1)
            Patterns = @(); Strings = @(); Fullwidth = @(); DeepHits = @(); Entropy = @()
            HitCount = 0; Sources = @(); ObfResult = $oFlags
            MixinHits = $null; BytecodeHits = $null; NetworkHits = $null
            FilenameToken = $null; IsWhitelisted = $script:cleanModWhitelist.Contains($baseName)
        })
        $clean.Remove($jar.Name) | Out-Null
    }
}
Write-Host "  │  100% done                                      " -ForegroundColor DarkMagenta
$obfHeavy = ($flagged | Where-Object { $_.ObfResult -and $_.ObfResult.Count -gt 0 }).Count
Write-Host "  └─ $obfHeavy jar(s) with obfuscation flags" -ForegroundColor DarkMagenta

# ── Phase 4: Mixin Injection + Bytecode Hook + Network Exfil Scan
Write-Host ""
Write-Host "  ┌─ " -ForegroundColor DarkMagenta -NoNewline
Write-Host "Phase 4" -ForegroundColor Magenta -NoNewline
Write-Host " · Mixin Injection + Bytecode Hooks + Network Exfil" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkMagenta
$pi = 0
foreach ($jar in $jars) {
    $pi++; $pct  = [math]::Floor(($pi / $total) * 100)
    $padN = $jar.Name.PadRight(40).Substring(0, [math]::Min(40, $jar.Name.Length))
    [Console]::Write("  │  $pct% $padN`r")
    $baseName      = Get-ModBaseName -FileName $jar.Name
    $isWhitelisted = $script:cleanModWhitelist.Contains($baseName)
    $mi3 = Get-Mod-Info-From-Jar -jarPath $jar.FullName
    if ($mi3.ModId -and $script:cleanModWhitelist.Contains($mi3.ModId)) { $isWhitelisted = $true }
    $mHits  = Invoke-MixinInjectionScan   -FilePath $jar.FullName -IsWhitelisted $isWhitelisted
    $bHits  = Invoke-BytecodeHookScan     -FilePath $jar.FullName -IsWhitelisted $isWhitelisted
    $nHits  = Invoke-NetworkExfilScan     -FilePath $jar.FullName -IsWhitelisted $isWhitelisted
    $anyNew = ($mHits.Count + $bHits.Count + $nHits.Count) -gt 0
    $existing = $flagged | Where-Object { $_.Name -eq $jar.Name } | Select-Object -First 1
    if ($existing) {
        $existing.MixinHits    = $mHits
        $existing.BytecodeHits = $bHits
        $existing.NetworkHits  = $nHits
    } elseif ($anyNew) {
        $flagged.Add([PSCustomObject]@{
            Name = $jar.Name; Path = $jar.FullName; Size = [math]::Round($jar.Length / 1KB, 1)
            Patterns = @(); Strings = @(); Fullwidth = @(); DeepHits = @(); Entropy = @()
            HitCount = 0; Sources = @(); ObfResult = $null
            MixinHits = $mHits; BytecodeHits = $bHits; NetworkHits = $nHits
            FilenameToken = $null; IsWhitelisted = $isWhitelisted
        })
        $clean.Remove($jar.Name) | Out-Null
    }
}
Write-Host "  │  100% done                                      " -ForegroundColor DarkMagenta
$p4count = ($flagged | Where-Object {
    ($_.MixinHits   -and $_.MixinHits.Count   -gt 0) -or
    ($_.BytecodeHits -and $_.BytecodeHits.Count -gt 0) -or
    ($_.NetworkHits  -and $_.NetworkHits.Count  -gt 0)
}).Count
Write-Host "  └─ $p4count jar(s) with mixin/bytecode/network flags" -ForegroundColor DarkMagenta

# ── Phase 5: Disallowed Mods
Write-Host ""
Write-Host "  ┌─ " -ForegroundColor DarkMagenta -NoNewline
Write-Host "Phase 5" -ForegroundColor Magenta -NoNewline
Write-Host " · Disallowed Mods Detection" -ForegroundColor DarkGray
Write-Host "  │" -ForegroundColor DarkMagenta
Write-Host "  │  scanning... " -ForegroundColor DarkGray -NoNewline
$disallowedFound = Find-DisallowedMods -Path $modsPath -JarFiles $jars
if ($disallowedFound.Count -gt 0) { Write-Host "$($disallowedFound.Count) disallowed mod(s)" -ForegroundColor Red }
else                               { Write-Host "clean" -ForegroundColor Cyan }
Write-Host "  └─ done" -ForegroundColor DarkMagenta

Start-Sleep -Milliseconds 300; Clear-Host

# ═════════════════════════════════════════════════════════
#  CLASSIFICATION
# ═════════════════════════════════════════════════════════
$criticalThreats = [System.Collections.Generic.List[PSObject]]::new()
$suspiciousFiles = [System.Collections.Generic.List[PSObject]]::new()
foreach ($mod in $flagged) {
    $isBlatant = $false

    if ($mod.HitCount -ge 20) { $isBlatant = $true }

    foreach ($str in $mod.Strings) {
        if ($str -match "SelfDestruct|AutoCrystal|Dqrkis Client|POT_CHEATS|Donut|cancelPacket|dropPacket|spoofPacket|setTimerSpeed|timerSpeed|grimBypass|ncpBypass|aacBypass|bypassAC|selfdestruct|reverseShell|sendWebhook|TokenGrabber|SessionStealer|discord\.com/api/webhooks|pastebin\.com/raw|grabify") {
            $isBlatant = $true; break
        }
    }

    if ($mod.FilenameToken -and $mod.HitCount -eq 0) {
        foreach ($t in @("vape","meteor","liquidbounce","wurst","futureclient","rusherhack","impactclient","aristois","dqrkis","doomsday","kamiblue","vapelite","novaclient","wolframclient","bleachhack")) {
            if ($mod.FilenameToken -match $t) { $isBlatant = $true; break }
        }
    }

    if ($mod.ObfResult -and ($mod.ObfResult | Where-Object { $_ -match "Runtime\.exec|HTTP POST|Fake mod identity" }).Count -gt 0) { $isBlatant = $true }

    if ($mod.NetworkHits -and ($mod.NetworkHits | Where-Object { $_ -match "discord\.com/api/webhooks|discordapp\.com/api/webhooks|pastebin\.com/raw|grabify|TokenGrabber|SessionStealer|ReverseShell|sendWebhook" }).Count -gt 0) { $isBlatant = $true }

    if ($mod.MixinHits -and ($mod.MixinHits | Where-Object { $_ -match "EndCrystalEntityMixin|ExplosionMixinAccessor|PlayerMoveC2SPacketMixin|ClientConnectionMixin|Excessive mixin count" }).Count -gt 0) { $isBlatant = $true }

    if ($isBlatant) {
        $hasRealHits = ($mod.HitCount -gt 0) -or
                       ($mod.MixinHits   -and $mod.MixinHits.Count   -gt 0) -or
                       ($mod.BytecodeHits -and $mod.BytecodeHits.Count -gt 0) -or
                       ($mod.NetworkHits  -and $mod.NetworkHits.Count  -gt 0) -or
                       ($mod.FilenameToken)
        $obfOnlyTrigger = (-not $hasRealHits) -and ($mod.ObfResult -and $mod.ObfResult.Count -gt 0)
        if ($obfOnlyTrigger) { $isBlatant = $false }
    }

    if ($isBlatant) { $criticalThreats.Add($mod) } else { $suspiciousFiles.Add($mod) }
}

# ═════════════════════════════════════════════════════════
#  FULL REPORT
# ═════════════════════════════════════════════════════════
Write-Host ""
Write-Host "   ┌──────────────────────────────────────────────────────────────────────────────────────┐" -ForegroundColor DarkGray
Write-Host "   │" -ForegroundColor DarkGray -NoNewline
Write-Host "      BlablablaModAnalyzer " -ForegroundColor Magenta -NoNewline
Write-Host "│ " -ForegroundColor DarkGray -NoNewline
Write-Host "SCAN RESULTS" -ForegroundColor Magenta -NoNewline
Write-Host "                                   │" -ForegroundColor DarkGray
Write-Host "   └──────────────────────────────────────────────────────────────────────────────────────┘" -ForegroundColor DarkGray
Write-Host ""

$fC = if ($flagged.Count -gt 0) { [System.ConsoleColor]::Red } else { [System.ConsoleColor]::Cyan }
Write-Border 'top' DarkGray
Write-RowFull ("  SCAN REPORT  ·  " + $scanTimestamp) Magenta DarkGray
Write-Border 'sep' DarkGray
Write-Row "  Modules   : " ($activeModules -join "  ·  ") Magenta White DarkGray
Write-Row "  Path      : " $modsPath DarkGray Gray DarkGray
Write-Row "  Files     : " "$($jars.Count) scanned" DarkGray White DarkGray
Write-Row "  Clean     : " "$($clean.Count)" DarkGray Cyan DarkGray
Write-Row "  JVM Issues: " "$($jvmResults.Count)" DarkGray $(if ($jvmResults.Count -gt 0) { [System.ConsoleColor]::Red } else { [System.ConsoleColor]::Cyan }) DarkGray
Write-Row "  Flagged   : " "$($flagged.Count)" DarkGray $fC DarkGray
Write-Row "  Disallowed: " "$($disallowedFound.Count)" DarkGray $(if ($disallowedFound.Count -gt 0) { [System.ConsoleColor]::Red } else { [System.ConsoleColor]::Cyan }) DarkGray
if ($mcStatus.Running) {
    Write-Row "  Minecraft : " " RUNNING   PID $($mcStatus.PID)   $($mcStatus.Uptime)   $($mcStatus.RAM) RAM" DarkGray Cyan DarkGray
} else {
    Write-Row "  Minecraft : " " not running" DarkGray DarkGray DarkGray
}
Write-Border 'bot' DarkGray

# ── JVM Issues
if ($jvmResults.Count -gt 0) {
    Write-Host ""
    Write-Border 'top' Red
    Write-RowFull "  ⚠  JVM ARGUMENT ISSUES ($($jvmResults.Count) finding(s))" Red Red
    Write-Border 'sep' Red
    foreach ($j in ($jvmResults | Where-Object { $_.Severity -eq "HIGH" })) {
        Write-Row "  [HIGH]  " "$($j.Type.PadRight(26)) $($j.Detail)" Red DarkGray Red
    }
    foreach ($j in ($jvmResults | Where-Object { $_.Severity -eq "MEDIUM" })) {
        Write-Row "  [MED]   " "$($j.Type.PadRight(26)) $($j.Detail)" Yellow DarkGray Yellow
    }
    foreach ($j in ($jvmResults | Where-Object { $_.Severity -eq "LOW" })) {
        Write-Row "  [LOW]   " "$($j.Type.PadRight(26)) $($j.Detail)" DarkGray DarkGray DarkGray
    }
    Write-Border 'bot' Red
}

# ── Critical threats
if ($criticalThreats.Count -gt 0) {
    Write-Host ""
    Write-Border 'top' Red
    Write-RowFull "  ⛔  CRITICAL — CONFIRMED CHEAT  ($($criticalThreats.Count) file(s))" Red Red
    foreach ($mod in $criticalThreats) {
        Write-Border 'sep' Red
        Write-Row "  [!!!] " $mod.Name White Red Red
        Write-Row "        " "Size: $($mod.Size) KB   Hits: $($mod.HitCount)" DarkGray DarkGray Red
        if ($mod.FilenameToken) { Write-Row "        " "Filename token: $($mod.FilenameToken)" DarkGray Red Red }
        $allHits = @($mod.Strings) + @($mod.Patterns) + @($mod.DeepHits) + @($mod.Fullwidth)
        foreach ($h in ($allHits | Select-Object -First 6)) { Write-Row "        " "• $h" DarkGray Red Red }
        if ($mod.MixinHits   -and $mod.MixinHits.Count   -gt 0) { foreach ($mh in ($mod.MixinHits   | Select-Object -First 3)) { Write-Row "        " "[MIX] $mh"  DarkGray Magenta Red } }
        if ($mod.BytecodeHits -and $mod.BytecodeHits.Count -gt 0) { foreach ($bh in ($mod.BytecodeHits | Select-Object -First 3)) { Write-Row "        " "[BYT] $bh"  DarkGray Magenta Red } }
        if ($mod.NetworkHits  -and $mod.NetworkHits.Count  -gt 0) { foreach ($nh in ($mod.NetworkHits  | Select-Object -First 3)) { Write-Row "        " "[NET] $nh"  DarkGray Magenta Red } }
        if ($mod.ObfResult) { foreach ($o in ($mod.ObfResult | Select-Object -First 3)) { Write-Row "        " "[OBF] $o" DarkGray Yellow Red } }
        if ($mod.Sources.Count -gt 0) { foreach ($s in ($mod.Sources | Select-Object -First 2)) { Write-Row "        " "[URL] $s" DarkGray DarkYellow Red } }
    }
    Write-Border 'bot' Red
}

# ── Suspicious files
if ($suspiciousFiles.Count -gt 0) {
    Write-Host ""
    Write-Border 'top' Yellow
    Write-RowFull "  ⚠  SUSPICIOUS FILES ($($suspiciousFiles.Count) file(s))" Yellow Yellow
    foreach ($mod in $suspiciousFiles) {
        Write-Border 'sep' DarkYellow
        Write-Row "  [?]  " $mod.Name White Yellow Yellow
        Write-Row "       " "Size: $($mod.Size) KB   Hits: $($mod.HitCount)" DarkGray DarkGray Yellow
        if ($mod.FilenameToken) { Write-Row "       " "Filename token: $($mod.FilenameToken)" DarkGray Yellow Yellow }
        $allHits = @($mod.Strings) + @($mod.Patterns) + @($mod.DeepHits) + @($mod.Fullwidth)
        foreach ($h in ($allHits | Select-Object -First 4)) { Write-Row "       " "• $h" DarkGray DarkGray Yellow }
        if ($mod.MixinHits   -and $mod.MixinHits.Count   -gt 0) { foreach ($mh in ($mod.MixinHits   | Select-Object -First 2)) { Write-Row "       " "[MIX] $mh" DarkGray DarkYellow Yellow } }
        if ($mod.BytecodeHits -and $mod.BytecodeHits.Count -gt 0) { foreach ($bh in ($mod.BytecodeHits | Select-Object -First 2)) { Write-Row "       " "[BYT] $bh" DarkGray DarkYellow Yellow } }
        if ($mod.NetworkHits  -and $mod.NetworkHits.Count  -gt 0) { foreach ($nh in ($mod.NetworkHits  | Select-Object -First 2)) { Write-Row "       " "[NET] $nh" DarkGray DarkYellow Yellow } }
        if ($mod.ObfResult) { foreach ($o in ($mod.ObfResult | Select-Object -First 2)) { Write-Row "       " "[OBF] $o" DarkGray DarkYellow Yellow } }
        if ($mod.Entropy.Count -gt 0) { Write-Row "       " "[ENT] High entropy classes detected" DarkGray DarkYellow Yellow }
    }
    Write-Border 'bot' Yellow
}

# ── Disallowed mods
if ($disallowedFound.Count -gt 0) {
    Write-Host ""
    Write-Border 'top' Yellow
    Write-RowFull "  ⛔  DISALLOWED MODS DETECTED ($($disallowedFound.Count))" Yellow Yellow
    Write-Border 'sep' Yellow
    foreach ($dm in $disallowedFound) {
        Write-Row "  [BAN]  " $dm.FileName White Yellow Yellow
        Write-Row "         " "Mod: $($dm.ModName)  ·  Matched by: $($dm.MatchedBy)" DarkGray DarkYellow Yellow
        if ($dm -ne $disallowedFound[-1]) { Write-Border 'sep' DarkYellow }
    }
    Write-Border 'bot' Yellow
}

# ── All clear banner
$totalIssues = $jvmResults.Count + $flagged.Count + $disallowedFound.Count
if ($totalIssues -eq 0) {
    Write-Host ""
    Write-Border 'top' Cyan
    Write-RowFull "  ✅  ALL CLEAR — No issues detected across all 5 phases" Cyan Cyan
    Write-Border 'bot' Cyan
}

# ── Naughty banner (shown when confirmed cheats are found)
if ($criticalThreats.Count -gt 0) {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "  ║" -ForegroundColor Red -NoNewline
    Write-Host "                                                                                  " -ForegroundColor Red -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ║" -ForegroundColor Red -NoNewline
    Write-Host "    ( ͡° ͜ʖ ͡°)   Naughty boy... why are you cheating?                           " -ForegroundColor Yellow -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ║" -ForegroundColor Red -NoNewline
    Write-Host "    You got $($criticalThreats.Count) confirmed cheat(s) in your mods folder!       " -ForegroundColor White -NoNewline
    Write-Host "                  ║" -ForegroundColor Red
    Write-Host "  ║" -ForegroundColor Red -NoNewline
    Write-Host "    Bad boy. Very bad boy. Go touch grass. 🌿                                    " -ForegroundColor Cyan -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ║" -ForegroundColor Red -NoNewline
    Write-Host "                                                                                  " -ForegroundColor Red -NoNewline
    Write-Host "║" -ForegroundColor Red
    Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
}

# ── Footer
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkGray
Write-Host "  ║" -ForegroundColor DarkGray -NoNewline; Write-Host "                    Analysis Complete!                     " -ForegroundColor Green -NoNewline;   Write-Host "║" -ForegroundColor DarkGray
Write-Host "  ║" -ForegroundColor DarkGray -NoNewline; Write-Host "      Special thanks to Tonynoh for helping me            " -ForegroundColor Magenta -NoNewline; Write-Host "║" -ForegroundColor DarkGray
Write-Host "  ║" -ForegroundColor DarkGray -NoNewline; Write-Host "      Credits to MeowModAnalyzer                          " -ForegroundColor Cyan -NoNewline;    Write-Host "║" -ForegroundColor DarkGray
Write-Host "  ║" -ForegroundColor DarkGray -NoNewline; Write-Host "      Discord : mecz.exe                                   " -ForegroundColor Yellow -NoNewline; Write-Host "║" -ForegroundColor DarkGray
Write-Host "  ╚══════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
