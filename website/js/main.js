var searchVisible = 0;
var transparent = true;
var fixedTop = false;
var navbar_initialized = false;

jQuery(document).ready(function(){
    body_height = jQuery("body").height();
    window_height = jQuery(window).height();
    window_width = jQuery(window).width();
    
    if (window_height > body_height) {
        jQuery("footer").css("position", "absolute").css("bottom", 0);
    } else {
        jQuery("footer").css("position", "relative").css("bottom", 0);
    }    
    
    if (window_width >= 768) {
        big_image = jQuery('.page-header[data-parallax="true"]');

        if(big_image.length != 0){
            jQuery(window).on('scroll', pk.checkScrollForPresentationPage);
        }
    }

    if(jQuery('.navbar[color-on-scroll]').length != 0){
        jQuery(window).on('scroll', pk.checkScrollForTransparentNavbar)
    }

    pk.initCollapseArea();

    jQuery('[data-toggle="tooltip"]').tooltip();
});


jQuery(document).on('click', '.navbar-toggler', function(){
    $toggle = jQuery(this);
    if(pk.misc.navbar_menu_visible == 1) {
        jQuery('html').removeClass('nav-open');
        pk.misc.navbar_menu_visible = 0;
        setTimeout(function(){
            $toggle.removeClass('toggled');
            jQuery('#bodyClick').remove();
        }, 550);
    } else {
        setTimeout(function(){
            $toggle.addClass('toggled');
        }, 580);

        div = '<div id="bodyClick"></div>';
        jQuery(div).appendTo("body").click(function() {
            jQuery('html').removeClass('nav-open');
            pk.misc.navbar_menu_visible = 0;
            jQuery('#bodyClick').remove();
            setTimeout(function(){
                $toggle.removeClass('toggled');
            }, 550);
        });

        jQuery('html').addClass('nav-open');
        pk.misc.navbar_menu_visible = 1;
    }
});

pk = {
    misc:{
        navbar_menu_visible: 0
    },

    checkScrollForPresentationPage: debounce(function(){
        oVal = (jQuery(window).scrollTop() / 3);
        big_image.css({
            'transform':'translate3d(0,' + oVal +'px,0)',
            '-webkit-transform':'translate3d(0,' + oVal +'px,0)',
            '-ms-transform':'translate3d(0,' + oVal +'px,0)',
            '-o-transform':'translate3d(0,' + oVal +'px,0)'
        });
    }, 4),

    checkScrollForTransparentNavbar: debounce(function() {
        if(jQuery(document).scrollTop() > jQuery(".navbar").attr("color-on-scroll") & !jQuery('body').hasClass('page')) {
            if(transparent) {
                transparent = false;
                jQuery('.navbar[color-on-scroll]').removeClass('navbar-transparent');
                jQuery('.navbar .navbar-brand img').attr('src', 'https://www.max.gwi.uni-muenchen.de/wp-content/themes/max/assets/img/logo_max_grey.png');
            }
        } else {
            if(!transparent) {
                transparent = true;
                jQuery('.navbar[color-on-scroll]').addClass('navbar-transparent');
                jQuery('.navbar .navbar-brand img').attr('src', 'https://www.max.gwi.uni-muenchen.de/wp-content/themes/max/assets/img/logo_max_white.png');
            }
        }
    }, 17),

    initCollapseArea: function(){
        jQuery('[data-toggle="pk-collapse"]').each(function () {
            var thisdiv = jQuery(this).attr("data-target");
            jQuery(thisdiv).addClass("pk-collapse");
        });

        jQuery('[data-toggle="pk-collapse"]').hover(function(){
            var thisdiv = jQuery(this).attr("data-target");
            if(!jQuery(this).hasClass('state-open')){
                jQuery(this).addClass('state-hover');
                jQuery(thisdiv).css({
                    'height':'30px'
                });
            }

        },
        function(){
            var thisdiv = jQuery(this).attr("data-target");
            jQuery(this).removeClass('state-hover');

            if(!jQuery(this).hasClass('state-open')){
                jQuery(thisdiv).css({
                    'height':'0px'
                });
            }
        }).click(function(event){
            event.preventDefault();

            var thisdiv = jQuery(this).attr("data-target");
            var height = jQuery(thisdiv).children('.panel-body').height();

            if(jQuery(this).hasClass('state-open')){
                jQuery(thisdiv).css({
                    'height':'0px',
                });
                jQuery(this).removeClass('state-open');
            } else {
                jQuery(thisdiv).css({
                    'height':height + 30,
                });
                jQuery(this).addClass('state-open');
            }
        });
    },
}

function debounce(func, wait, immediate) {
    var timeout;
    return function() {
        var context = this, args = arguments;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            timeout = null;
            if (!immediate) func.apply(context, args);
        }, wait);
        if (immediate && !timeout) func.apply(context, args);
    };
};
