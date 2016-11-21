CIF.FamiliesIndex = do ->
  _init = ->
    _fixedHeaderTableColumns()
    _handleScrollTable()
    # _resizeNiceScroll()

  _fixedHeaderTableColumns = ->
    if !$('table.families tbody tr td').hasClass('noresults')
      $('table.families').dataTable(
        'bPaginate': false
        'bFilter': false
        'bInfo': false
        'bSort': false
        'sScrollY': 'auto'
        'bAutoWidth': true
        'sScrollX': '100%'
        'sScrollXInner': '100%')

  _handleScrollTable = ->
    $(window).load ->
      $('.families-table .dataTables_scrollBody').niceScroll fixed:true

  _resizeNiceScroll = ->
    $('.navbar-minimalize').click ->
      console.log($('.families-table .dataTables_scrollBody').getNiceScroll())
      $('.families-table .dataTables_scrollBody').getNiceScroll ->
        window.dispatchEvent new Event('resize')

  { init: _init }
