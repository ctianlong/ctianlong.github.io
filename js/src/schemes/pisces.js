$(document).ready(function(){function e(){return n.height()+10}function i(n){return t.css({"margin-top":n})}var n=$(".header-inner"),t=$("#sidebar"),r=window.matchMedia("(min-width: 991px)");i(e()).show(),r.addListener(function(n){n.matches&&i(e())})});