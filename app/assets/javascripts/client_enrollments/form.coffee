CIF.Client_enrollmentsNew = CIF.Client_enrollmentsCreate = do -> 
  _init = ->
    _initSelect2()
    _handlePreventCheckbox()

  _initSelect2 = ->
    $('select').select2()

  _handlePreventCheckbox = ->
    form = $('form.simple_form')
    $(form).on 'submit', (e) ->
      checkboxes = $(form).find('input[type="checkbox"]')
      otherInputs = $(form).find('input:not([type="checkbox"], [type="file"], [type="hidden"], [type="submit"])')
      checked = false

      for checkbox in checkboxes
        if $(checkbox).prop('checked')
          checked = true
          break

      if checkboxes.length > 0 and !checked and otherInputs.length == 0
        e.preventDefault()
        $('#message').text("Please select a checkbox")

  { init: _init }