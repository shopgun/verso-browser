import Verso from '../lib/coffeescript/verso'
verso = null

beforeEach ->
    document.body.innerHTML = """
        <div class="verso">
            <div class="verso__scroller">
                <div class="verso__page-spread" data-id="page1" data-width="80">
                    <div class="verso__page">page1</div>
                </div>
                <div class="verso__page-spread" data-id="page2" data-width="100">
                    <div class="verso__page">page2</div>
                </div>
                <div class="verso__page-spread" data-id="page3" data-width="80">
                    <div class="verso__page">page3</div>
                </div>

            </div>
        </div>
    """

    verso = new Verso(document.querySelector('.verso')).start()

    return

afterEach ->
    verso.destroy()
    verso = null

    return

test 'Page spreads getting their active state set', ->
    expect(document.querySelector('[data-id=page1]').getAttribute('data-active')).toBe 'true'

    return

test 'Page spreads getting their left value set relative to each other', ->
    expect(document.querySelector('[data-id=page1]').style.left).toBe '0%'
    expect(document.querySelector('[data-id=page2]').style.left).toBe '80%'

    return

test 'Navigation to next page', ->
    verso.next()

    expect(document.querySelector('[data-id=page1]').getAttribute('data-active')).toBe 'false'
    expect(document.querySelector('[data-id=page2]').getAttribute('data-active')).toBe 'true'
    expect(document.querySelector('[data-id=page1]').style.left).toBe '0%'
    expect(document.querySelector('[data-id=page2]').style.left).toBe '80%'
    expect(document.querySelector('[data-id=page3]').style.left).toBe '180%'

    return

test 'Navigation to next page triggers beforeNavigation with proper data', (done) ->
    beforeNavigationCallback = (data) ->
        expect(data).toEqual { currentPosition: 0, newPosition: 1 }
        done()
    
    verso.bind "beforeNavigation", beforeNavigationCallback
    verso.next()
