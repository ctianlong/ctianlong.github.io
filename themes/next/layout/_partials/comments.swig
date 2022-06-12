{% if page.comments %}
  <div class="comments" id="comments">
    {% if (theme.duoshuo and theme.duoshuo.shortname) or theme.duoshuo_shortname %}
      <div class="ds-thread" data-thread-key="{{ page.path }}"
           data-title="{{ page.title }}" data-url="{{ page.permalink }}">
      </div>
    {% elseif theme.facebook_sdk.enable and theme.facebook_comments_plugin.enable %}
      <div class="fb-comments"
           data-href="{{ page.permalink }}"
           data-numposts="{{ theme.facebook_comments_plugin.num_of_posts }}"
           data-width="{{ theme.facebook_comments_plugin.width }}"
           data-colorscheme="{{ theme.facebook_comments_plugin.scheme }}">
      </div>
    {% elseif theme.disqus_shortname %}
      <div id="disqus_thread">
        <noscript>
          Please enable JavaScript to view the
          <a href="//disqus.com/?ref_noscript">comments powered by Disqus.</a>
        </noscript>
      </div>
    {% elseif theme.hypercomments_id %}
      <div id="hypercomments_widget"></div>
    {% elseif theme.gentie_productKey %}
      <div id="cloud-tie-wrapper" class="cloud-tie-wrapper"></div>
    {% elseif theme.youyan_uid %}
      <div id="uyan_frame"></div>
    {% endif %}
  </div>

  {% if theme.valine.enable and theme.valine.appid and theme.valine.appkey %}
    <script src="//unpkg.com/leancloud-storage/dist/av-min.js"></script>
    <script src="//unpkg.com/valine/dist/Valine.min.js"></script>
    <script type="text/javascript">
      var GUEST = ['nick','mail','link'];
      var guest = '{{ theme.valine.guest_info }}';
      guest = guest.split(',').filter(item=>{
        return GUEST.indexOf(item)>-1;
      });
      new Valine({
          el: '#comments' ,
          verify: {{ theme.valine.verify }},
          notify: {{ theme.valine.notify }},
          appId: '{{ theme.valine.appid }}',
          appKey: '{{ theme.valine.appkey }}',
          placeholder: '{{ theme.valine.placeholder }}',
          avatar:'{{ theme.valine.avatar }}',
          guest_info:guest,
          pageSize:'{{ theme.valine.pageSize }}' || 10
      });
    </script>
  {% endif %}

{% endif %}
