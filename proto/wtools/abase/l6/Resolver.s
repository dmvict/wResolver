( function _Resolver_s_()
{

'use strict';


/**
 * Collection of cross-platform routines to resolve complex data structures.
  @module Tools/base/Resolver
*/

/**
 * Collection of cross-platform routines to resolve a sub-structure from a complex data structure.
  @namespace Tools.Resolver
  @memberof module:Tools/base/Resolver
*/

if( typeof module !== 'undefined' )
{

  let _ = require( '../../../wtools/Tools.s' );

  _.include( 'wLooker' );
  _.include( 'wReplicator' );
  _.include( 'wSelector' );
  _.include( 'wPathTools' );

}

let _global = _global_;
let _ = _global_.wTools;
let Parent = _.replicator.Replicator;
_.resolver = _.resolver || Object.create( null );
_.resolver.functor = _.resolver.functor || Object.create( null );

_.assert( !!_realGlobal_ );

// --
// relations
// --

let Defaults = _.mapExtend( null, _.selector.select.body.defaults );

Defaults.root = null;
Defaults.onSelectorUp = null;
Defaults.onSelectorDown = null;
Defaults.onSelectorReplicate = onSelectorReplicate;
Defaults.onSelectorUndecorate = _.selector.onSelectorUndecorate;
Defaults.onQuantitativeFail = null;
Defaults.recursive = 0;
Defaults.compositeSelecting = 0;

//

let SelectorDefaults = _.mapExtend( null, _.selector.select.body.defaults );

SelectorDefaults.replicateIteration = null;
// SelectorDefaults.compositeSelecting = null; /* yyy */

/* xxx : it.iterator.dst should be undefined */

// --
// extend looker
// --

function resolve_head( routine, args )
{
  return Self.head( routine, args );
}

//

function resolve_body( o )
{
  let it = o;
  _.assert( it.Looker.iterationProper( it ) );
  it.perform();
  return it.result;
}

_.routineExtend( resolve_body, _.selector.select.body );

var defaults = resolve_body.defaults = Defaults;

_.assert( _.routineIs( defaults.onSelectorUndecorate ) );

// --
// extend looker
// --

function head( routine, args )
{
  _.assert( arguments.length === 2 );
  let o = Self.optionsFromArguments( args );
  if( _.routineIs( routine ) )
  o.Looker = o.Looker || routine.defaults.Looker || Self;
  else
  o.Looker = o.Looker || routine.Looker || Self;
  if( _.routineIs( routine ) ) /* zzz : remove "if" later */
  _.routineOptionsPreservingUndefines( routine, o );
  else
  _.routineOptionsPreservingUndefines( null, o, routine );
  o.Looker.optionsForm( routine, o );
  o.optionsForSelect = o.Looker.selectorOptionsForSelectFrom( o );
  let it = o.Looker.optionsToIteration( o );
  return it;
}

//

function optionsFromArguments( args )
{
  let o = args[ 0 ]
  if( args.length === 2 )
  {
    _.assert( !_.resolver.iterationIs( args[ 0 ] ) );
    o = { src : args[ 0 ], selector : args[ 1 ] }
  }

  _.assert( args.length === 1 || args.length === 2 );
  _.assert( arguments.length === 1 );
  _.assert( _.mapIs( o ) );

  return o;
}

//

function optionsForm( routine, o )
{
  Parent.optionsForm.call( this, routine, o );

  _.assert( _.mapIs( o ) );
  _.assert( !o.recursive || !!o.onSelectorReplicate, () => 'For recursive selection onSelectorReplicate should be defined' );

  const onUp2 = o.onUp; /* xxx : write down to o? */
  const onDown2 = o.onDown;

  if( o.root === null )
  o.root = o.src;

  o.onUp = onUp;
  o.onDown = onDown;

  if( o.compositeSelecting )
  {

    if( o.onSelectorReplicate === onSelectorReplicate || o.onSelectorReplicate === null )
    o.onSelectorReplicate = _.resolver.functor.onSelectorReplicateComposite();
    if( o.onSelectorDown === null )
    o.onSelectorDown = _.resolver.functor.onSelectorDownComposite();

    _.assert( _.routineIs( o.onSelectorReplicate ) );
    _.assert( _.routineIs( o.onSelectorDown ) );

  }

  o.srcForSelect = o.src;
  o.resolvingRecursive = o.recursive;
  o.recursive = Infinity;
  o.src = o.selector;

  return o;

  /* */

  function onUp()
  {
    let it = this;
    _.assert( !it.rit );
    let selector
    let visited = [];
    let counter = 0;

    selector = o.onSelectorReplicate.call( it, { selector : it.src, counter } );

    do
    {

      if( _.strIs( selector ) )
      {
        it.src = selector;
        it.iterable = null;
        it.srcChanged();
        let sit = it._select( visited );
        selector = undefined;
        if( sit.result !== undefined && o.resolvingRecursive && visited.length <= o.resolvingRecursive )
        {
          counter += 1;
          selector = o.onSelectorReplicate.call( it, { selector : sit.result, counter } );
          if( selector === undefined )
          {
            if( !sit.error )
            it.dst = sit.result;
            it.continue = false;
            it.dstMaking = false; /* zzz */
          }
        }
        else
        {
          if( !sit.error )
          it.dst = sit.result;
          it.continue = false;
          it.dstMaking = false; /* zzz */
        }
      }
      else if( selector !== undefined )
      {
        if( selector && selector.composite === _.resolver.compositeSymbol )
        {
          if( !it.compositeRoot )
          it.compositeRoot = it;
          it.composite = true;
        }
        it.src = selector;
        it.iterable = null;
        it.srcChanged();
        selector = undefined;
      }

    }
    while( selector !== undefined );

    if( o.onSelectorUp )
    o.onSelectorUp.call( it, o );

    if( onUp2 )
    onUp2.apply( it, arguments );

  }

  /* */

  function onDown()
  {
    let it = this;

    if( onDown2 )
    onDown2.apply( it, arguments );

    if( o.onSelectorDown )
    o.onSelectorDown.call( it, o );
  }

}

//

function optionsToIteration( o )
{
  let it = Parent.optionsToIteration.call( this, o );
  _.assert( it.compositeRoot !== undefined );
  _.assert( it.resolve1Options === undefined );
  _.assert( it.replicateIteration === undefined );
  _.assert( it.recursive === Infinity );
  return it;
}

//

function iteratorMake( o )
{
  let iterator = _.replicator.Replicator.iteratorMake.apply( this, arguments );
  _.assert( iterator.iteratorProper( iterator ) );
  return iterator;
}

//

function selectorOptionsForSelectFrom( o )
{
  let it = this;

  _.assert( _.aux.is( o ) );
  _.assert( !!o.Looker.ResolverSelector );
  _.assert( !!o.Looker.ResolverSelector );

  let o2 = _.mapOnly_( null, o, it.ResolverSelector.exec.defaults );
  o2.src = o.srcForSelect;
  o2.Looker = o.Looker.ResolverSelector;
  o2.recursive = Infinity;
  o2.onSelectorUndecorate = o.onSelectorUndecorate;
  o2.onQuantitativeFail = o.onQuantitativeFail;
  o2.onDownEnd = o.onDownEnd;
  o2.onUpBegin = o.onUpBegin;
  o2.onUpEnd = o.onUpEnd;

  // o2.missingAction = 'throw'; /* yyy */
  // debugger;

  delete o2.recursive;
  delete o2.onUp;
  delete o2.onDown;
  delete o2.root;

  _.assert( !o2.it );
  _.assert( !o2.iterator );

  return o2;
}

//

function selectorIterate()
{
  let it = this;
  let result = _.selector.Selector.iterate.apply( it, arguments );
  _.assert( it.composite === undefined );
  _.assert( it.compositeRoot === undefined );
  return result;
}

//

/**
 * @summary Selects elements from source object( src ) using provided pattern( selector ).
 * @param {} src Source entity.
 * @param {String} selector Pattern that matches against elements in a entity.
 *
 * @example //resolve element with key 'a1'
 * _.resolve( { a1 : 1, a2 : 2 }, 'a1' ); // 1
 *
 * @example //resolve any that starts with 'a'
 * _.resolve( { a1 : 1, a2 : 2 }, 'a*' ); // { a1 : 1, a2 : 1 }
 *
 * @example //resolve with constraint, only one element should be selected
 * _.resolve( { a1 : 1, a2 : 2 }, 'a*=1' ); // error
 *
 * @example //resolve with constraint, two elements
 * _.resolve( { a1 : 1, a2 : 2 }, 'a*=2' ); // { a1 : 1, a2 : 1 }
 *
 * @example //resolve inner element using path selector
 * _.resolve( { a : { b : { c : 1 } } }, 'a/b' ); //{ c : 1 }
 *
 * @example //resolve value of each property with name 'x'
 * _.resolve( { a : { x : 1 }, b : { x : 2 }, c : { x : 3 } }, '*\/x' ); //{a: 1, b: 2, c: 3}
 *
 * @example // resolve root
 * _.resolve( { a : { b : { c : 1 } } }, '/' );
 *
 * @function resolve
 * @memberof module:Tools/base/Resolver.Tools( module::Resolver )
*/

let resolve = _.routineUnite( resolve_head, resolve_body );

//

function performBegin()
{
  let it = this;
  Parent.performBegin.apply( it, arguments );
  _.assert( Object.is( it.originalSrc, it.src ) );
  _.assert( arguments.length === 0 );
  _.assert( it.compositeRoot !== undefined );
  return it;
}

//

function performEnd()
{
  let it = this;
  _.assert( it.compositeRoot !== undefined );
  Parent.performEnd.apply( it, arguments );
  return it;
}

//

function _select( visited )
{
  let it = this;

  _.assert( _.strIs( it.src ) );
  _.assert( arguments.length === 1 );

  if( _.longHas( visited, it.src ) ) /* qqq : cover please */
  return;

  let op = _.mapExtend( null, it.optionsForSelect ); /* xxx : optimize */
  op.replicateIteration = it;
  op.selector = it.src;
  op.visited = visited;

  _.assert( _.strIs( op.selector ) );
  _.assert( !_.longHas( visited, op.selector ), () => `Loop selecting ${op.selector}` );

  visited.push( op.selector );

  _.assert( _.strIs( op.selector ) );
  _.assert( !!it.ResolverSelector );

  op.Looker = it.ResolverSelector;
  _.assert( _.routineIs( op.Looker.exec ) );

  debugger;
  let sit = op.Looker.exec( op );
  debugger;

  _.assert( sit.iterator === op );
  _.assert( sit.iterator.state === 2 );

  return sit;
}

//

function onSelectorReplicate( o )
{
  let it = this;
  if( _.strIs( o.selector ) )
  return o.selector;
}

//

function onSelectorReplicateComposite( fop )
{

  fop = _.routineOptions( onSelectorReplicateComposite, arguments );
  fop.prefix = _.arrayAs( fop.prefix );
  fop.postfix = _.arrayAs( fop.postfix );
  fop.onSelectorReplicate = fop.onSelectorReplicate || onSelectorReplicate;

  _.assert( _.strsAreAll( fop.prefix ) );
  _.assert( _.strsAreAll( fop.postfix ) );
  _.assert( _.routineIs( fop.onSelectorReplicate ) );

  return function onSelectorReplicateComposite( o )
  {
    let it = this;
    _.assert( !it.rit );
    let selector = o.selector;

    if( !_.strIs( selector ) )
    return;

    let selector2 = _.strSplitFast
    ({
      src : selector,
      delimeter : _.arrayAppendArrays( [], [ fop.prefix, fop.postfix ] ),
    });

    if( selector2[ 0 ] === '' )
    selector2.splice( 0, 1 );
    if( selector2[ selector2.length-1 ] === '' )
    selector2.pop();

    if( selector2.length < 3 )
    {
      if( fop.isStrippedSelector )
      return fop.onSelectorReplicate.call( it, o );
      else
      return;
    }

    if( selector2.length === 3 )
    if( _.strsEquivalentAny( fop.prefix, selector2[ 0 ] ) && _.strsEquivalentAny( fop.postfix, selector2[ 2 ] ) )
    {
      return fop.onSelectorReplicate.call( it, _.mapExtend( null, o, { selector : selector2[ 1 ] } ) );
    }

    selector2 = _.strSplitsCoupledGroup({ splits : selector2, prefix : '{', postfix : '}' });

    if( fop.onSelectorReplicate )
    selector2 = selector2.map( ( split ) =>
    {
      if( !_.arrayIs( split ) )
      return split;

      _.assert( split.length === 3 );

      let split1 = fop.onSelectorReplicate.call( it, _.mapExtend( null, o, { selector : split[ 1 ] } ) );
      if( split1 === undefined )
      {
        return split.join( '' );
      }
      else
      {
        if( fop.rewrapping )
        return split[ 0 ] + split1 + split[ 2 ];
        else
        return split;
      }
    });

    selector2 = selector2.map( ( split ) => _.arrayIs( split ) ? split.join( '' ) : split );
    selector2.composite = _.resolver.compositeSymbol;

    return selector2;
  }

  function onSelectorReplicate( o )
  {
    return o.selector;
  }

}

onSelectorReplicateComposite.defaults =
{
  prefix : '{',
  postfix : '}',
  onSelectorReplicate : null,
  isStrippedSelector : 0, /* treat selector beyond affixes like "head::c/c2" as selector */
  rewrapping : 1,
}

//

function onSelectorDownComposite( fop )
{
  return function onSelectorDownComposite()
  {
    let it = this;
    if( it.continue && _.arrayIs( it.dst ) && it.src.composite === _.resolver.compositeSymbol )
    {
      it.dst = _.strJoin( it.dst );
    }
  }
}

// xxx
// //
//
// function define(  )
// {
//
//
//
//   // ResolverExtraReplicator.ResolverSelector = ResolverExtraSelector;
//   // ResolverExtraReplicator.ResolverReplicator = ResolverExtraReplicator;
//   // ResolverExtraSelector.ResolverSelector = ResolverExtraSelector;
//   // ResolverExtraSelector.ResolverReplicator = ResolverExtraReplicator;
//
// }

// --
// relations
// --

let LookerResolverSelector =
{
  constructor : function ResolverSelector(){},
  selectorOptionsForSelectFrom,
  iterate : selectorIterate,
  /* xxx : introduce optionsForm for Selector? */
  /* xxx : head */
}

let IteratorResolverSelector =
{
  replicateIteration : null,
}

let IterationResolverSelector =
{
}

let IterationPreserveResolverSelector =
{
}

let ResolverSelectorPreserve =
{
}

let ResolverSelector = _.looker.define
({
  name : 'ResolverSelector',
  parent : _.Selector,
  defaults : SelectorDefaults,
  looker : LookerResolverSelector,
  iterator : IteratorResolverSelector,
  iteration : IterationResolverSelector,
  iterationPreserve : IterationPreserveResolverSelector,
});

_.assert( ResolverSelector.exec.defaults.missingAction !== undefined );
_.assert( ResolverSelector.exec.defaults.replicateIteration !== undefined );

/* xxx : pass defaults */

//

let LookerResolverReplicator =
{
  constructor : function ResolverReplicator(){},
  head,
  exec : resolve,
  optionsFromArguments,
  optionsForm,
  optionsToIteration,
  iteratorMake,
  selectorOptionsForSelectFrom,
  performBegin,
  performEnd,
  _select,
  ResolverSelector,
}

let IteratorResolverReplicator =
{
  srcForSelect : null,
  optionsForSelect : null,
  result : null, /* xxx : redundant */
}

let IterationResolverReplicator =
{
}

let IterationPreserveResolverReplicator =
{
  composite : false,
  compositeRoot : null,
}

/* xxx : redefine define */
let ResolverReplicator = _.looker.define
({
  name : 'ResolverReplicator',
  parent : _.replicator.Replicator,
  defaults : Defaults,
  looker : LookerResolverReplicator,
  iterator : IteratorResolverReplicator,
  iteration : IterationResolverReplicator,
  iterationPreserve : IterationPreserveResolverReplicator,
});

//

ResolverReplicator.ResolverSelector = ResolverSelector;
ResolverReplicator.ResolverReplicator = ResolverReplicator;
ResolverReplicator.ResolverSelectorPreserve = ResolverSelectorPreserve;

ResolverSelector.ResolverSelector = ResolverSelector;
ResolverSelector.ResolverReplicator = ResolverReplicator;
ResolverSelector.ResolverSelectorPreserve = ResolverSelectorPreserve;

//

let compositeSymbol = Symbol.for( 'composite' );

var FunctorExtension =
{
  ... _.selector.functor,
  onSelectorReplicateComposite,
  onSelectorDownComposite,
}

let ResolverExtension =
{

  ... _.replicator,

  resolve,

  onSelectorReplicate,
  compositeSymbol,

  Resolver : ResolverReplicator,
  ResolverReplicator,
  ResolverSelector,

}

let ToolsExtension =
{

  resolve,

}

let Self = ResolverReplicator;
_.mapSupplement( _, ToolsExtension );
_.mapSupplement( _.resolver, ResolverExtension );
_.mapSupplement( _.resolver.functor, FunctorExtension );

// --
// export
// --

if( typeof module !== 'undefined' )
module[ 'exports' ] = _;

})();
