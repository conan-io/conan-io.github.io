// BOOTSTRAP VARS
const bootstrap_sm = '769px';
const bootstrap_md = '992px';

jQuery(document).ready(function ($) {

  //refresh on mobile orientationchange
  $(window).bind('orientationchange', function (event) {
    location.reload(true);
  });

  //--ALL PAGES--//
  //HAMBURGER
  $('.hamburger').on('click',function () {
    let ham = $(this);
    ham.toggleClass('is-active');
    toggleMenu($, ham);
  });

  var searchBox = $('select#siteSearch');

  searchBox.select2({
    placeholder: "Search",
    allowClear: true
  });;

  searchBox.on('select2:select', function (e) {
    e.preventDefault();
    let homeURL = window.location.href;
    let val = searchBox.val()[0];
    // let hp = window.location.href;
    window.location.href = val;
  });

  if ( window.matchMedia("(min-width: "+bootstrap_md+")").matches ) {
    inPagePostsMatchRowsHeight($, 2);
  }


});


function inPagePostsMatchRowsHeight($, numberOfElementsInRow) {
  let singlePagePosts = $('.post-link-couple');
  let postsCounter    = 0;
  let marker          = 1;
  let couple          = [];

  singlePagePosts.each(function () {
    postsCounter++;
    if (postsCounter <= numberOfElementsInRow) {
      couple.push($(this));
    }
    if (postsCounter === numberOfElementsInRow) {
      cMatchHeight($, couple);
      couple = [];
      marker++;
      postsCounter = 0;
    }
  });
}

function cMatchHeight($, set) {
  let maxHeight = 0;

  for (var i = 0; i < set.length; i++) {
    let that = set[i];
    let thisHeight = that.outerHeight();
    if (thisHeight > maxHeight) {
      maxHeight = thisHeight;
    }
  }

  for (var i = 0; i < set.length; i++) {
    let that = set[i];
    that.outerHeight(maxHeight);
  }
}

//MENU TOGGLE
function toggleMenu($, ham) {

  let hamOffset       = ham.offset();
  let hamOffsetRight  = ($(window).width() - (hamOffset.left + ham.outerWidth()));
  let hamOffsetBottom = hamOffset.top + ham.outerHeight();
  let headerNav       = $('nav#headerNav');

  if (!headerNav.hasClass('toggled')) {
    headerNav.appendTo('body');
  }

  headerNav.addClass('toggled shadow');

  headerNav
    .toggleClass('is-visible')
    .removeClass('align-items-center d-lg-flex')
    .css('top',hamOffsetBottom)
    .css('right',hamOffsetRight);
}
