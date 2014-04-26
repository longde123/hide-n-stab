package hidenstab;

import flash.net.Socket;
import flash.events.Event;
import hidenstab.Defs;
import hidenstab.Stabber;


class Client
{
    static var _current:Client;
    public static var current(get, never):Client;
    static function get_current()
    {
        if (_current == null) _current = new Client();
        return _current;
    }
    
    public static function init()
    {
        current.connect();
    }
    
    var socket:Socket;
    
    var chars:Map<Int, Stabber>;
    var id:Guid;
    
    public function new()
    {
        chars = new Map();
        lastSeen = new Map();
        thisSeen = new Map();
        
        connect();
    }
    
    public function connect() {
        socket = new Socket();
        socket.addEventListener(Event.CONNECT, onConnect);
        var host = Defs.HOST;
        var port = Defs.PORT;
        socket.connect(host, port);
    }
    
    public function update() {
        while (socket.bytesAvailable > 0) {
            readMessage();
        }
    }
    
    var lastSeen:Map<Int, Bool>;
    var thisSeen:Map<Int, Bool>;
    
    function onConnect(d:Dynamic)
    {
    }
    
    function readMessage()
    {
        var msgType = socket.readByte();
        switch(msgType)
        {
            case Defs.MSG_SEND_GUID: {
                // receive this character's ID
                id = socket.readUnsignedInt();
            }
            case Defs.MSG_SEND_CHARS: {
                // character updates
                var n = socket.readByte();
                for (i in 0 ... n)
                {
                    var guid = socket.readUnsignedInt();
                    var char:Stabber = chars.get(guid);
                    
                    if (char == null)
                    {
                        char = StabberPool.get(guid);
                        chars[guid] = char;
                    }
                    
                    char.x = socket.readByte();
                    char.y = socket.readByte();
                    char.moving.x = socket.readByte();
                    char.moving.y = socket.readByte();
                    var stateChanged = socket.readByte() == 1;
                    if (stateChanged)
                    {
                        var newState:UInt = socket.readByte();
                        char.state = Stabber.intToState.get(newState);
                    }
                    
                    thisSeen.set(guid, true);
                }
            }
        }
        
        for (id in lastSeen.keys())
        {
            if (!thisSeen.exists(id))
            {
                var thisChar = chars.get(id);
                thisChar.scene.remove(thisChar);
                chars.remove(id);
            }
            
            lastSeen.remove(id);
        }
        
        var emptyMap = lastSeen;
        lastSeen = thisSeen;
        thisSeen = emptyMap;
    }
}