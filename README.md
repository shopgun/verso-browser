# Verso

preload? rendering a template acts as preloading
alternate between single/double paged? react on resize and reinstantiate Verso
define in HTML or JS? define elements in HTML but allow JS to manipulate each slide when rendering


the sgn browser sdk exposes a method to get pages based on viewport width

what about Ember? we can push an "outro" element to the pages array that is empty. when Verso wants to render the element we can render a component into it. we miss the opportunity to define the slides in HTMLBars. ish. we can make a {{verso-pages}} component, which is stand-alone. here we can render anything we want. the sgn browser sdk is more boxes in in the sense that we need to support flexible pages.
