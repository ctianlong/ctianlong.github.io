$(function(){
          var music = document.getElementById("bgMusic");
          var musicArr=[
            {url:'https://static.tongjilab.cn/music/mp3/Sunburst.mp3',title:"sunburst"},
            {url:'https://static.tongjilab.cn/music/mp3/Victory.mp3',title:"victory"}
          ];

          $("#audioBtn").click(function(){
            if(music.paused){
              music.play();
              var $audioBtn = $("#audioBtn");
              $audioBtn.children("i").addClass("fa-spin");
              $audioBtn.attr('title',"正在播放:"+$audioBtn.attr('titleInfo'));
            }else{
              music.pause();
              var $audioBtn = $("#audioBtn");
              $audioBtn.children("i").removeClass("fa-spin");
              $audioBtn.removeAttr("title");
            }
          });

          function randomMusic(){
            var isone=$("#bgMusic").attr('src');
            var noone=musicArr[parseInt(Math.random()*musicArr.length)];
            while(noone.url==isone){noone=musicArr[parseInt(Math.random()*musicArr.length)];}
            $("#bgMusic").attr('src',noone.url);
            $("#audioBtn").attr('titleInfo',noone.title);
          }

          randomMusic();

          $("#bgMusic").on('ended',function(){
            randomMusic();
            var $audioBtn = $("#audioBtn");
            $audioBtn.attr('title',"正在播放:"+$audioBtn.attr('titleInfo'));
            music.play();
          });
        });
