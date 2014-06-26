response.ok """

<link href="/assets/screen.css" rel="stylesheet">
<link href="//marquee-cdn.net/doodad-0.3.0.css" rel="stylesheet">
<body>
    <script>
        window.CONTENT_API_ROOT = '#{ env.CONTENT_API_ROOT }';
        window.CONTENT_API_TOKEN = '#{ env.CONTENT_API_TOKEN }';
        window.FILEPICKER_API_KEY = '#{ env.FILEPICKER_API_KEY }';
    </script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.5.2/underscore-min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.0.3/jquery.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/backbone.js/1.1.0/backbone-min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
    <script src="//marquee-cdn.net/doodad-0.3.0.js"></script>
    <script>
        (function(a){if(window.filepicker){return}var b=a.createElement("script");b.type="text/javascript";b.async=!0;b.src=("https:"===a.location.protocol?"https:":"http:")+"//api.filepicker.io/v1/filepicker.js";var c=a.getElementsByTagName("script")[0];c.parentNode.insertBefore(b,c);var d={};d._queue=[];var e="pick,pickMultiple,pickAndStore,read,write,writeUrl,export,convert,store,storeUrl,remove,stat,setKey,constructWidget,makeDropPane".split(",");var f=function(a,b){return function(){b.push([a,arguments])}};for(var g=0;g<e.length;g++){d[e[g]]=f(e[g],d._queue)}window.filepicker=d})(document);
        filepicker.setKey(window.FILEPICKER_API_KEY);
    </script>
    <script src="/assets/ui.js"></script>
</body>
"""
