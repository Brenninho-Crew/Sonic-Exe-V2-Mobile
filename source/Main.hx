package;

import openfl.display.BlendMode;
import openfl.text.TextFormat;
import openfl.display.Application;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
#if android
import openfl.events.TouchEvent;
import openfl.ui.Multitouch;
import openfl.ui.MultitouchInputMode;
#end

class Main extends Sprite
{
        var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
        var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
        var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
        var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
        var framerate:Int = 60; // Reduzido para 60 FPS no mobile para economizar bateria
        var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
        var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

        public static var watermarks = true; // Whether to put Kade Engine liteartly anywhere

        // Controle de toque para Android
        #if android
        private var touchStartX:Float = 0;
        private var touchStartY:Float = 0;
        private var touchStartTime:Float = 0;
        private var isTouchActive:Bool = false;
        #end

        public static function main():Void
        {
                // quick checks 
                Lib.current.addChild(new Main());
        }

        public function new()
        {
                super();

                if (stage != null)
                {
                        init();
                }
                else
                {
                        addEventListener(Event.ADDED_TO_STAGE, init);
                }
        }

        public static var webmHandler:WebmHandler;

        private function init(?E:Event):Void
        {
                if (hasEventListener(Event.ADDED_TO_STAGE))
                {
                        removeEventListener(Event.ADDED_TO_STAGE, init);
                }

                setupGame();
                
                #if android
                setupAndroid();
                #end
        }

        #if android
        private function setupAndroid():Void
        {
                // Configurar multitouch
                Multitouch.inputMode = MultitouchInputMode.TOUCH_POINT;
                Multitouch.maxTouchPoints = 5; // Suporte até 5 toques simultâneos
                
                // Prevenir comportamento padrão de touch no browser (não aplicável no Android nativo, mas mantido)
                FlxG.android.preventDefaultDefaultTouchMove = true;
                
                // Adicionar listeners para botões físicos do Android
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onAndroidKeyDown);
                stage.addEventListener(KeyboardEvent.KEY_UP, onAndroidKeyUp);
                
                // Listeners para toque
                stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin);
                stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);
                
                // Configurar taxa de atualização para economia de bateria
                openfl.Lib.current.stage.frameRate = 60;
                
                // Otimizações de memória para Android
                #if cpp
                cpp.vm.GC.enable(true);
                cpp.vm.GC.setRunInterval(10); // Forçar GC a rodar mais frequentemente no Android
                #end
        }

        private function onAndroidKeyDown(event:KeyboardEvent):Void
        {
                switch(event.keyCode)
                {
                        case Keyboard.BACK:
                                // Botão de voltar do Android
                                event.preventDefault();
                                handleBackButton();
                                
                        case Keyboard.MENU:
                                // Botão de menu do Android
                                event.preventDefault();
                                // Pode abrir opções ou pausar o jogo
                                
                        case Keyboard.SEARCH:
                                // Botão de busca (incomum)
                                event.preventDefault();
                }
        }

        private function onAndroidKeyUp(event:KeyboardEvent):Void
        {
                switch(event.keyCode)
                {
                        case Keyboard.BACK:
                                // Prevenir comportamento padrão
                                event.preventDefault();
                }
        }

        private function handleBackButton():Void
        {
                // Lógica para o botão de voltar
                if (FlxG.state != null)
                {
                        var currentState = FlxG.state;
                        
                        // Se estiver no jogo, volta para o menu
                        if (Std.isOfType(currentState, PlayState))
                        {
                                FlxG.switchState(new MainMenuState());
                        }
                        // Se estiver no menu principal ou título, pergunta se quer sair
                        else if (Std.isOfType(currentState, MainMenuState) || Std.isOfType(currentState, TitleState))
                        {
                                #if android
                                // Mostrar diálogo de confirmação para sair
                                openfl.system.System.exit();
                                #else
                                FlxG.switchState(new TitleState());
                                #end
                        }
                        // Qualquer outro estado, volta para o menu principal
                        else
                        {
                                FlxG.switchState(new MainMenuState());
                        }
                }
        }

        private function onTouchBegin(event:TouchEvent):Void
        {
                touchStartX = event.stageX;
                touchStartY = event.stageY;
                touchStartTime = haxe.Timer.stamp();
                isTouchActive = true;
                
                // Simular clique do mouse para compatibilidade
                var mouseEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_DOWN, 
                        true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                stage.dispatchEvent(mouseEvent);
        }

        private function onTouchMove(event:TouchEvent):Void
        {
                if (!isTouchActive) return;
                
                // Simular movimento do mouse
                var mouseEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_MOVE, 
                        true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                stage.dispatchEvent(mouseEvent);
        }

        private function onTouchEnd(event:TouchEvent):Void
        {
                if (!isTouchActive) return;
                
                var touchEndTime = haxe.Timer.stamp();
                var touchDuration = touchEndTime - touchStartTime;
                
                // Detectar se foi um toque rápido (tap) ou longo (hold)
                if (touchDuration < 0.3) // Menos de 300ms
                {
                        // Simular clique
                        var mouseDownEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_DOWN, 
                                true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                        stage.dispatchEvent(mouseDownEvent);
                        
                        var mouseUpEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_UP, 
                                true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                        stage.dispatchEvent(mouseUpEvent);
                        
                        var clickEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.CLICK, 
                                true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                        stage.dispatchEvent(clickEvent);
                }
                else
                {
                        // Apenas soltar
                        var mouseUpEvent = new openfl.events.MouseEvent(openfl.events.MouseEvent.MOUSE_UP, 
                                true, false, event.stageX, event.stageY, event.stageX, event.stageY);
                        stage.dispatchEvent(mouseUpEvent);
                }
                
                isTouchActive = false;
        }
        #end

        private function setupGame():Void
        {
                var stageWidth:Int = Lib.current.stage.stageWidth;
                var stageHeight:Int = Lib.current.stage.stageHeight;

                if (zoom == -1)
                {
                        var ratioX:Float = stageWidth / gameWidth;
                        var ratioY:Float = stageHeight / gameHeight;
                        zoom = Math.min(ratioX, ratioY);
                        gameWidth = Math.ceil(stageWidth / zoom);
                        gameHeight = Math.ceil(stageHeight / zoom);
                }

                // Ajustes para Android
                #if android
                // Reduzir qualidade gráfica se necessário para performance
                if (gameWidth > 1920 || gameHeight > 1080)
                {
                        FlxG.save.data.quality = "LOW";
                }
                framerate = 60; // Garantir 60 FPS no Android
                #end

                #if cpp
                initialState = Caching; //change back to Caching once done with testing
                game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
                #else
                game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
                #end
                addChild(game);

                var ourSource:String = "assets/videos/DO NOT DELETE OR GAME WILL CRASH/dontDelete.webm";

                #if web
                var str1:String = "HTML CRAP";
                var vHandler = new VideoHandler();
                vHandler.init1();
                vHandler.video.name = str1;
                addChild(vHandler.video);
                vHandler.init2();
                GlobalVideo.setVid(vHandler);
                vHandler.source(ourSource);
                #elseif desktop
                var str1:String = "WEBM SHIT"; 
                var webmHandle = new WebmHandler();
                webmHandle.source(ourSource);
                webmHandle.makePlayer();
                webmHandle.webm.name = str1;
                addChild(webmHandle.webm);
                GlobalVideo.setWebm(webmHandle);
                #elseif android
                // Android usa o mesmo sistema de desktop para WebM
                var str1:String = "WEBM ANDROID"; 
                var webmHandle = new WebmHandler();
                webmHandle.source(ourSource);
                webmHandle.makePlayer();
                webmHandle.webm.name = str1;
                addChild(webmHandle.webm);
                GlobalVideo.setWebm(webmHandle);
                #end

                #if !mobile
                fpsCounter = new FPS(10, 3, 0xFFFFFF);
                addChild(fpsCounter);
                toggleFPS(FlxG.save.data.fps);
                #else
                // No mobile, FPS é opcional (pode ser ativado nas configurações)
                if (FlxG.save.data.showFPS)
                {
                        fpsCounter = new FPS(10, 3, 0xFFFFFF);
                        addChild(fpsCounter);
                        toggleFPS(true);
                }
                #end
        }

        var game:FlxGame;

        var fpsCounter:FPS;

        public function toggleFPS(fpsEnabled:Bool):Void {
                if (fpsCounter != null)
                {
                        fpsCounter.visible = fpsEnabled;
                }
        }

        public function changeFPSColor(color:FlxColor)
        {
                if (fpsCounter != null)
                {
                        fpsCounter.textColor = color;
                }
        }

        public function setFPSCap(cap:Float)
        {
                openfl.Lib.current.stage.frameRate = cap;
        }

        public function getFPSCap():Float
        {
                return openfl.Lib.current.stage.frameRate;
        }

        public function getFPS():Float
        {
                return (fpsCounter != null) ? fpsCounter.currentFPS : 0;
        }
}