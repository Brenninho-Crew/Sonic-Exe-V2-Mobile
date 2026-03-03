package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
#if android
import openfl.filesystem.File;
#end

class Paths
{
        inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

        static var currentLevel:String;
        
        // Cache para evitar verificações repetidas de existência de arquivos
        static var fileExistsCache:Map<String, Bool> = new Map<String, Bool>();
        
        // Armazenamento externo para Android (mods, downloads, etc)
        #if android
        public static var externalStoragePath:String = "";
        public static var internalStoragePath:String = "";
        
        // Inicializar caminhos de armazenamento Android
        static function initAndroidPaths():Void
        {
                if (externalStoragePath == "")
                {
                        try
                        {
                                // Tenta obter o caminho do armazenamento externo (SD Card)
                                var extStorage = File.applicationStorageDirectory;
                                externalStoragePath = extStorage.nativePath + "/";
                                
                                // Caminho para armazenamento interno
                                internalStoragePath = File.applicationDirectory.nativePath + "/";
                                
                                // Criar diretórios necessários se não existirem
                                createAndroidDirectories();
                        }
                        catch (e:Dynamic)
                        {
                                trace("Erro ao inicializar caminhos Android: " + e);
                                externalStoragePath = "";
                                internalStoragePath = "";
                        }
                }
        }
        
        static function createAndroidDirectories():Void
        {
                try
                {
                        // Criar diretórios para mods e dados do jogo
                        var modsDir = File.applicationStorageDirectory.resolvePath("mods");
                        if (!modsDir.exists)
                                modsDir.createDirectory();
                                
                        var songsDir = File.applicationStorageDirectory.resolvePath("songs");
                        if (!songsDir.exists)
                                songsDir.createDirectory();
                                
                        var dataDir = File.applicationStorageDirectory.resolvePath("data");
                        if (!dataDir.exists)
                                dataDir.createDirectory();
                }
                catch (e:Dynamic)
                {
                        trace("Erro ao criar diretórios Android: " + e);
                }
        }
        
        // Verificar se arquivo existe no armazenamento externo
        static function fileExistsExternal(path:String):Bool
        {
                try
                {
                        var file = File.applicationStorageDirectory.resolvePath(path);
                        return file.exists;
                }
                catch (e:Dynamic)
                {
                        return false;
                }
        }
        #end

        static public function setCurrentLevel(name:String)
        {
                currentLevel = name.toLowerCase();
        }

        static function getPath(file:String, type:AssetType, library:Null<String>)
        {
                // Gerar chave única para cache
                var cacheKey = file + ":" + (library != null ? library : "null") + ":" + type;
                
                // Verificar cache primeiro
                if (fileExistsCache.exists(cacheKey))
                {
                        if (fileExistsCache[cacheKey])
                        {
                                return getCachedPath(file, library);
                        }
                        else
                        {
                                return getFallbackPath(file, type, library);
                        }
                }
                
                var resultPath:String = null;
                
                #if android
                // No Android, verificar primeiro no armazenamento externo (para mods)
                initAndroidPaths();
                
                // Tentar no external storage (mods, downloads)
                if (library == null || library == "mods")
                {
                        var externalPath = getAndroidExternalPath(file, library);
                        if (externalPath != null && fileExistsExternal(externalPath))
                        {
                                resultPath = externalPath;
                                fileExistsCache[cacheKey] = true;
                                return resultPath;
                        }
                }
                #end
                
                // Tentar no caminho normal da biblioteca
                if (library != null)
                {
                        resultPath = getLibraryPath(file, library);
                        if (OpenFlAssets.exists(resultPath, type))
                        {
                                fileExistsCache[cacheKey] = true;
                                return resultPath;
                        }
                }

                // Tentar no currentLevel
                if (currentLevel != null)
                {
                        var levelPath = getLibraryPathForce(file, currentLevel);
                        if (OpenFlAssets.exists(levelPath, type))
                        {
                                fileExistsCache[cacheKey] = true;
                                return levelPath;
                        }

                        levelPath = getLibraryPathForce(file, "shared");
                        if (OpenFlAssets.exists(levelPath, type))
                        {
                                fileExistsCache[cacheKey] = true;
                                return levelPath;
                        }
                }

                // Tentar no preload
                resultPath = getPreloadPath(file);
                if (OpenFlAssets.exists(resultPath, type))
                {
                        fileExistsCache[cacheKey] = true;
                        return resultPath;
                }
                
                // Se nada funcionar, marcar como não existente e retornar fallback
                fileExistsCache[cacheKey] = false;
                return getFallbackPath(file, type, library);
        }
        
        static function getCachedPath(file:String, ?library:String):String
        {
                if (library != null)
                        return getLibraryPath(file, library);
                if (currentLevel != null)
                        return getLibraryPathForce(file, currentLevel);
                return getPreloadPath(file);
        }
        
        static function getFallbackPath(file:String, type:AssetType, ?library:String):String
        {
                // Tentar retornar qualquer caminho possível como fallback
                if (library != null)
                        return getLibraryPath(file, library);
                if (currentLevel != null)
                        return getLibraryPathForce(file, currentLevel);
                return getPreloadPath(file);
        }
        
        #if android
        static function getAndroidExternalPath(file:String, ?library:String):String
        {
                try
                {
                        var basePath = externalStoragePath;
                        
                        if (library != null && library != "mods")
                        {
                                basePath += library + "/";
                        }
                        
                        // Mapear tipos de arquivo para subpastas apropriadas
                        if (file.indexOf("images/") == 0 || file.indexOf(".png") > -1)
                        {
                                basePath += "images/";
                        }
                        else if (file.indexOf("sounds/") == 0 || file.indexOf(".ogg") > -1 || file.indexOf(".mp3") > -1)
                        {
                                basePath += "sounds/";
                        }
                        else if (file.indexOf("music/") == 0)
                        {
                                basePath += "music/";
                        }
                        else if (file.indexOf("data/") == 0)
                        {
                                basePath += "data/";
                        }
                        else if (file.indexOf("videos/") == 0)
                        {
                                basePath += "videos/";
                        }
                        
                        return basePath + file;
                }
                catch (e:Dynamic)
                {
                        return null;
                }
        }
        #end

        static public function getLibraryPath(file:String, library = "preload")
        {
                return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
        }

        inline static function getLibraryPathForce(file:String, library:String)
        {
                return '$library:assets/$library/$file';
        }

        inline static function getPreloadPath(file:String)
        {
                return 'assets/$file';
        }

        inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
        {
                return getPath(file, type, library);
        }

        inline static public function lua(key:String,?library:String)
        {
                return getPath('data/$key.lua', TEXT, library);
        }

        inline static public function luaImage(key:String, ?library:String)
        {
                return getPath('data/$key.png', IMAGE, library);
        }

        inline static public function txt(key:String, ?library:String)
        {
                return getPath('data/$key.txt', TEXT, library);
        }

        inline static public function xml(key:String, ?library:String)
        {
                return getPath('data/$key.xml', TEXT, library);
        }

        inline static public function json(key:String, ?library:String)
        {
                return getPath('data/$key.json', TEXT, library);
        }

        static public function sound(key:String, ?library:String)
        {
                return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
        }

        inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
        {
                return sound(key + FlxG.random.int(min, max), library);
        }

        inline static public function video(key:String, ?library:String)
        {        
                trace('assets/videos/$key.mp4');
                #if android
                // No Android, tentar MP4 primeiro, depois WebM
                var mp4Path = getPath('videos/$key.mp4', BINARY, library);
                if (OpenFlAssets.exists(mp4Path, BINARY))
                        return mp4Path;
                return getPath('videos/$key.webm', BINARY, library);
                #else
                return getPath('videos/$key.mp4', BINARY, library);
                #end
        }

        inline static public function music(key:String, ?library:String)
        {
                return getPath('music/$key.$SOUND_EXT', MUSIC, library);
        }

        inline static public function voices(song:String)
        {
                var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
                switch (songLowercase) {
                        case 'dad-battle': songLowercase = 'dadbattle';
                        case 'philly-nice': songLowercase = 'philly';
                }
                
                #if android
                // No Android, verificar primeiro no external storage (mods de música)
                var externalVoices = getAndroidExternalPath('songs/${songLowercase}/Voices.$SOUND_EXT', null);
                if (externalVoices != null && fileExistsExternal(externalVoices))
                        return externalVoices;
                #end
                
                return 'songs:assets/songs/${songLowercase}/Voices.$SOUND_EXT';
        }

        inline static public function inst(song:String)
        {
                var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
                switch (songLowercase) {
                        case 'dad-battle': songLowercase = 'dadbattle';
                        case 'philly-nice': songLowercase = 'philly';
                }
                
                #if android
                // No Android, verificar primeiro no external storage (mods de música)
                var externalInst = getAndroidExternalPath('songs/${songLowercase}/Inst.$SOUND_EXT', null);
                if (externalInst != null && fileExistsExternal(externalInst))
                        return externalInst;
                #end
                
                return 'songs:assets/songs/${songLowercase}/Inst.$SOUND_EXT';
        }

        inline static public function image(key:String, ?library:String)
        {
                #if android
                // No Android, tentar PNG e JPG
                var pngPath = getPath('images/$key.png', IMAGE, library);
                if (OpenFlAssets.exists(pngPath, IMAGE))
                        return pngPath;
                        
                var jpgPath = getPath('images/$key.jpg', IMAGE, library);
                if (OpenFlAssets.exists(jpgPath, IMAGE))
                        return jpgPath;
                        
                return pngPath; // Fallback para PNG
                #else
                return getPath('images/$key.png', IMAGE, library);
                #end
        }

        inline static public function font(key:String)
        {
                #if android
                // No Android, tentar diferentes formatos de fonte
                var ttfPath = 'assets/fonts/$key.ttf';
                if (OpenFlAssets.exists(ttfPath, FONT))
                        return ttfPath;
                        
                var otfPath = 'assets/fonts/$key.otf';
                if (OpenFlAssets.exists(otfPath, FONT))
                        return otfPath;
                        
                return ttfPath;
                #else
                return 'assets/fonts/$key';
                #end
        }

        inline static public function getSparrowAtlas(key:String, ?library:String)
        {
                #if android
                // Tentar carregar com cache para evitar recarregamento
                var xmlPath = file('images/$key.xml', library);
                var pngPath = image(key, library);
                
                if (OpenFlAssets.exists(xmlPath, TEXT) && OpenFlAssets.exists(pngPath, IMAGE))
                {
                        return FlxAtlasFrames.fromSparrow(pngPath, xmlPath);
                }
                
                // Tentar formato alternativo
                xmlPath = file('images/$key.xml', "shared");
                if (OpenFlAssets.exists(xmlPath, TEXT))
                {
                        return FlxAtlasFrames.fromSparrow(pngPath, xmlPath);
                }
                #end
                
                return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
        }

        inline static public function getPackerAtlas(key:String, ?library:String)
        {
                return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
        }
        
        // Função para limpar cache (útil quando mods são carregados/descarregados)
        static public function clearCache():Void
        {
                fileExistsCache.clear();
        }
        
        #if android
        // Função específica para verificar se um mod existe no Android
        static public function modExists(modName:String):Bool
        {
                initAndroidPaths();
                var modPath = externalStoragePath + "mods/" + modName + "/";
                var modDir = File.applicationStorageDirectory.resolvePath("mods/" + modName);
                return modDir.exists && modDir.isDirectory;
        }
        
        // Função para listar mods disponíveis
        static public function listMods():Array<String>
        {
                initAndroidPaths();
                var mods:Array<String> = [];
                
                try
                {
                        var modsDir = File.applicationStorageDirectory.resolvePath("mods");
                        if (modsDir.exists && modsDir.isDirectory)
                        {
                                var files = modsDir.getDirectoryListing();
                                for (file in files)
                                {
                                        if (file.isDirectory)
                                        {
                                                mods.push(file.name);
                                        }
                                }
                        }
                }
                catch (e:Dynamic)
                {
                        trace("Erro ao listar mods: " + e);
                }
                
                return mods;
        }
        #end
}