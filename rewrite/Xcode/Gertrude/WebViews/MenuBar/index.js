(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const i of document.querySelectorAll('link[rel="modulepreload"]'))n(i);new MutationObserver(i=>{for(const r of i)if(r.type==="childList")for(const l of r.addedNodes)l.tagName==="LINK"&&l.rel==="modulepreload"&&n(l)}).observe(document,{childList:!0,subtree:!0});function _(i){const r={};return i.integrity&&(r.integrity=i.integrity),i.referrerPolicy&&(r.referrerPolicy=i.referrerPolicy),i.crossOrigin==="use-credentials"?r.credentials="include":i.crossOrigin==="anonymous"?r.credentials="omit":r.credentials="same-origin",r}function n(i){if(i.ep)return;i.ep=!0;const r=_(i);fetch(i.href,r)}})();var B,c,me,P,C,J,ge,R={},be=[],Le=/acit|ex(?:s|g|n|p|$)|rph|grid|ows|mnc|ntw|ine[ch]|zoo|^ord|itera/i;function w(e,t){for(var _ in t)e[_]=t[_];return e}function ke(e){var t=e.parentNode;t&&t.removeChild(e)}function j(e,t,_){var n,i,r,l={};for(r in t)r=="key"?n=t[r]:r=="ref"?i=t[r]:l[r]=t[r];if(arguments.length>2&&(l.children=arguments.length>3?B.call(arguments,2):_),typeof e=="function"&&e.defaultProps!=null)for(r in e.defaultProps)l[r]===void 0&&(l[r]=e.defaultProps[r]);return L(e,l,n,i,null)}function L(e,t,_,n,i){var r={type:e,props:t,key:_,ref:n,__k:null,__:null,__b:0,__e:null,__d:void 0,__c:null,__h:null,constructor:void 0,__v:i??++me};return i==null&&c.vnode!=null&&c.vnode(r),r}function N(e){return e.children}function Fe(e,t,_,n,i){var r;for(r in _)r==="children"||r==="key"||r in t||D(e,r,null,_[r],n);for(r in t)i&&typeof t[r]!="function"||r==="children"||r==="key"||r==="value"||r==="checked"||_[r]===t[r]||D(e,r,t[r],_[r],n)}function Q(e,t,_){t[0]==="-"?e.setProperty(t,_??""):e[t]=_==null?"":typeof _!="number"||Le.test(t)?_:_+"px"}function D(e,t,_,n,i){var r;e:if(t==="style")if(typeof _=="string")e.style.cssText=_;else{if(typeof n=="string"&&(e.style.cssText=n=""),n)for(t in n)_&&t in _||Q(e.style,t,"");if(_)for(t in _)n&&_[t]===n[t]||Q(e.style,t,_[t])}else if(t[0]==="o"&&t[1]==="n")r=t!==(t=t.replace(/Capture$/,"")),t=t.toLowerCase()in e?t.toLowerCase().slice(2):t.slice(2),e.l||(e.l={}),e.l[t+r]=_,_?n||e.addEventListener(t,r?Y:X,r):e.removeEventListener(t,r?Y:X,r);else if(t!=="dangerouslySetInnerHTML"){if(i)t=t.replace(/xlink(H|:h)/,"h").replace(/sName$/,"s");else if(t!=="width"&&t!=="height"&&t!=="href"&&t!=="list"&&t!=="form"&&t!=="tabIndex"&&t!=="download"&&t in e)try{e[t]=_??"";break e}catch{}typeof _=="function"||(_==null||_===!1&&t.indexOf("-")==-1?e.removeAttribute(t):e.setAttribute(t,_))}}function X(e){P=!0;try{return this.l[e.type+!1](c.event?c.event(e):e)}finally{P=!1}}function Y(e){P=!0;try{return this.l[e.type+!0](c.event?c.event(e):e)}finally{P=!1}}function k(e,t){this.props=e,this.context=t}function E(e,t){if(t==null)return e.__?E(e.__,e.__.__k.indexOf(e)+1):null;for(var _;t<e.__k.length;t++)if((_=e.__k[t])!=null&&_.__e!=null)return _.__e;return typeof e.type=="function"?E(e):null}function we(e){var t,_;if((e=e.__)!=null&&e.__c!=null){for(e.__e=e.__c.base=null,t=0;t<e.__k.length;t++)if((_=e.__k[t])!=null&&_.__e!=null){e.__e=e.__c.base=_.__e;break}return we(e)}}function Me(e){P?setTimeout(e):ge(e)}function ee(e){(!e.__d&&(e.__d=!0)&&C.push(e)&&!V.__r++||J!==c.debounceRendering)&&((J=c.debounceRendering)||Me)(V)}function V(){var e,t,_,n,i,r,l,u;for(C.sort(function(f,a){return f.__v.__b-a.__v.__b});e=C.shift();)e.__d&&(t=C.length,n=void 0,i=void 0,l=(r=(_=e).__v).__e,(u=_.__P)&&(n=[],(i=w({},r)).__v=r.__v+1,G(u,r,i,_.__n,u.ownerSVGElement!==void 0,r.__h!=null?[l]:null,n,l??E(r),r.__h),Ne(n,r),r.__e!=l&&we(r)),C.length>t&&C.sort(function(f,a){return f.__v.__b-a.__v.__b}));V.__r=0}function Ce(e,t,_,n,i,r,l,u,f,a){var o,h,p,s,d,$,v,m=n&&n.__k||be,b=m.length;for(_.__k=[],o=0;o<t.length;o++)if((s=_.__k[o]=(s=t[o])==null||typeof s=="boolean"?null:typeof s=="string"||typeof s=="number"||typeof s=="bigint"?L(null,s,null,null,s):Array.isArray(s)?L(N,{children:s},null,null,null):s.__b>0?L(s.type,s.props,s.key,s.ref?s.ref:null,s.__v):s)!=null){if(s.__=_,s.__b=_.__b+1,(p=m[o])===null||p&&s.key==p.key&&s.type===p.type)m[o]=void 0;else for(h=0;h<b;h++){if((p=m[h])&&s.key==p.key&&s.type===p.type){m[h]=void 0;break}p=null}G(e,s,p=p||R,i,r,l,u,f,a),d=s.__e,(h=s.ref)&&p.ref!=h&&(v||(v=[]),p.ref&&v.push(p.ref,null,s),v.push(h,s.__c||d,s)),d!=null?($==null&&($=d),typeof s.type=="function"&&s.__k===p.__k?s.__d=f=$e(s,f,e):f=Se(e,s,p,m,d,f),typeof _.type=="function"&&(_.__d=f)):f&&p.__e==f&&f.parentNode!=e&&(f=E(p))}for(_.__e=$,o=b;o--;)m[o]!=null&&(typeof _.type=="function"&&m[o].__e!=null&&m[o].__e==_.__d&&(_.__d=Pe(n).nextSibling),Ee(m[o],m[o]));if(v)for(o=0;o<v.length;o++)He(v[o],v[++o],v[++o])}function $e(e,t,_){for(var n,i=e.__k,r=0;i&&r<i.length;r++)(n=i[r])&&(n.__=e,t=typeof n.type=="function"?$e(n,t,_):Se(_,n,n,i,n.__e,t));return t}function W(e,t){return t=t||[],e==null||typeof e=="boolean"||(Array.isArray(e)?e.some(function(_){W(_,t)}):t.push(e)),t}function Se(e,t,_,n,i,r){var l,u,f;if(t.__d!==void 0)l=t.__d,t.__d=void 0;else if(_==null||i!=r||i.parentNode==null)e:if(r==null||r.parentNode!==e)e.appendChild(i),l=null;else{for(u=r,f=0;(u=u.nextSibling)&&f<n.length;f+=1)if(u==i)break e;e.insertBefore(i,r),l=r}return l!==void 0?l:i.nextSibling}function Pe(e){var t,_,n;if(e.type==null||typeof e.type=="string")return e.__e;if(e.__k){for(t=e.__k.length-1;t>=0;t--)if((_=e.__k[t])&&(n=Pe(_)))return n}return null}function G(e,t,_,n,i,r,l,u,f){var a,o,h,p,s,d,$,v,m,b,x,H,Z,A,U,g=t.type;if(t.constructor!==void 0)return null;_.__h!=null&&(f=_.__h,u=t.__e=_.__e,t.__h=null,r=[u]),(a=c.__b)&&a(t);try{e:if(typeof g=="function"){if(v=t.props,m=(a=g.contextType)&&n[a.__c],b=a?m?m.props.value:a.__:n,_.__c?$=(o=t.__c=_.__c).__=o.__E:("prototype"in g&&g.prototype.render?t.__c=o=new g(v,b):(t.__c=o=new k(v,b),o.constructor=g,o.render=De),m&&m.sub(o),o.props=v,o.state||(o.state={}),o.context=b,o.__n=n,h=o.__d=!0,o.__h=[],o._sb=[]),o.__s==null&&(o.__s=o.state),g.getDerivedStateFromProps!=null&&(o.__s==o.state&&(o.__s=w({},o.__s)),w(o.__s,g.getDerivedStateFromProps(v,o.__s))),p=o.props,s=o.state,o.__v=t,h)g.getDerivedStateFromProps==null&&o.componentWillMount!=null&&o.componentWillMount(),o.componentDidMount!=null&&o.__h.push(o.componentDidMount);else{if(g.getDerivedStateFromProps==null&&v!==p&&o.componentWillReceiveProps!=null&&o.componentWillReceiveProps(v,b),!o.__e&&o.shouldComponentUpdate!=null&&o.shouldComponentUpdate(v,o.__s,b)===!1||t.__v===_.__v){for(t.__v!==_.__v&&(o.props=v,o.state=o.__s,o.__d=!1),t.__e=_.__e,t.__k=_.__k,t.__k.forEach(function(O){O&&(O.__=t)}),x=0;x<o._sb.length;x++)o.__h.push(o._sb[x]);o._sb=[],o.__h.length&&l.push(o);break e}o.componentWillUpdate!=null&&o.componentWillUpdate(v,o.__s,b),o.componentDidUpdate!=null&&o.__h.push(function(){o.componentDidUpdate(p,s,d)})}if(o.context=b,o.props=v,o.__P=e,H=c.__r,Z=0,"prototype"in g&&g.prototype.render){for(o.state=o.__s,o.__d=!1,H&&H(t),a=o.render(o.props,o.state,o.context),A=0;A<o._sb.length;A++)o.__h.push(o._sb[A]);o._sb=[]}else do o.__d=!1,H&&H(t),a=o.render(o.props,o.state,o.context),o.state=o.__s;while(o.__d&&++Z<25);o.state=o.__s,o.getChildContext!=null&&(n=w(w({},n),o.getChildContext())),h||o.getSnapshotBeforeUpdate==null||(d=o.getSnapshotBeforeUpdate(p,s)),U=a!=null&&a.type===N&&a.key==null?a.props.children:a,Ce(e,Array.isArray(U)?U:[U],t,_,n,i,r,l,u,f),o.base=t.__e,t.__h=null,o.__h.length&&l.push(o),$&&(o.__E=o.__=null),o.__e=!1}else r==null&&t.__v===_.__v?(t.__k=_.__k,t.__e=_.__e):t.__e=Re(_.__e,t,_,n,i,r,l,f);(a=c.diffed)&&a(t)}catch(O){t.__v=null,(f||r!=null)&&(t.__e=u,t.__h=!!f,r[r.indexOf(u)]=null),c.__e(O,t,_)}}function Ne(e,t){c.__c&&c.__c(t,e),e.some(function(_){try{e=_.__h,_.__h=[],e.some(function(n){n.call(_)})}catch(n){c.__e(n,_.__v)}})}function Re(e,t,_,n,i,r,l,u){var f,a,o,h=_.props,p=t.props,s=t.type,d=0;if(s==="svg"&&(i=!0),r!=null){for(;d<r.length;d++)if((f=r[d])&&"setAttribute"in f==!!s&&(s?f.localName===s:f.nodeType===3)){e=f,r[d]=null;break}}if(e==null){if(s===null)return document.createTextNode(p);e=i?document.createElementNS("http://www.w3.org/2000/svg",s):document.createElement(s,p.is&&p),r=null,u=!1}if(s===null)h===p||u&&e.data===p||(e.data=p);else{if(r=r&&B.call(e.childNodes),a=(h=_.props||R).dangerouslySetInnerHTML,o=p.dangerouslySetInnerHTML,!u){if(r!=null)for(h={},d=0;d<e.attributes.length;d++)h[e.attributes[d].name]=e.attributes[d].value;(o||a)&&(o&&(a&&o.__html==a.__html||o.__html===e.innerHTML)||(e.innerHTML=o&&o.__html||""))}if(Fe(e,p,h,i,u),o)t.__k=[];else if(d=t.props.children,Ce(e,Array.isArray(d)?d:[d],t,_,n,i&&s!=="foreignObject",r,l,r?r[0]:_.__k&&E(_,0),u),r!=null)for(d=r.length;d--;)r[d]!=null&&ke(r[d]);u||("value"in p&&(d=p.value)!==void 0&&(d!==e.value||s==="progress"&&!d||s==="option"&&d!==h.value)&&D(e,"value",d,h.value,!1),"checked"in p&&(d=p.checked)!==void 0&&d!==e.checked&&D(e,"checked",d,h.checked,!1))}return e}function He(e,t,_){try{typeof e=="function"?e(t):e.current=t}catch(n){c.__e(n,_)}}function Ee(e,t,_){var n,i;if(c.unmount&&c.unmount(e),(n=e.ref)&&(n.current&&n.current!==e.__e||He(n,null,t)),(n=e.__c)!=null){if(n.componentWillUnmount)try{n.componentWillUnmount()}catch(r){c.__e(r,t)}n.base=n.__P=null,e.__c=void 0}if(n=e.__k)for(i=0;i<n.length;i++)n[i]&&Ee(n[i],t,_||typeof e.type!="function");_||e.__e==null||ke(e.__e),e.__=e.__e=e.__d=void 0}function De(e,t,_){return this.constructor(e,_)}function Ve(e,t,_){var n,i,r;c.__&&c.__(e,t),i=(n=typeof _=="function")?null:_&&_.__k||t.__k,r=[],G(t,e=(!n&&_||t).__k=j(N,null,[e]),i||R,R,t.ownerSVGElement!==void 0,!n&&_?[_]:i?null:t.firstChild?B.call(t.childNodes):null,r,!n&&_?_:i?i.__e:t.firstChild,n),Ne(r,e)}B=be.slice,c={__e:function(e,t,_,n){for(var i,r,l;t=t.__;)if((i=t.__c)&&!i.__)try{if((r=i.constructor)&&r.getDerivedStateFromError!=null&&(i.setState(r.getDerivedStateFromError(e)),l=i.__d),i.componentDidCatch!=null&&(i.componentDidCatch(e,n||{}),l=i.__d),l)return i.__E=i}catch(u){e=u}throw e}},me=0,P=!1,k.prototype.setState=function(e,t){var _;_=this.__s!=null&&this.__s!==this.state?this.__s:this.__s=w({},this.state),typeof e=="function"&&(e=e(w({},_),this.props)),e&&w(_,e),e!=null&&this.__v&&(t&&this._sb.push(t),ee(this))},k.prototype.forceUpdate=function(e){this.__v&&(this.__e=!0,e&&this.__h.push(e),ee(this))},k.prototype.render=N,C=[],ge=typeof Promise=="function"?Promise.prototype.then.bind(Promise.resolve()):setTimeout,V.__r=0;var K,y,z,te,_e=0,xe=[],F=[],ne=c.__b,re=c.__r,oe=c.diffed,ie=c.__c,le=c.unmount;function Ae(e,t){c.__h&&c.__h(y,e,_e||t),_e=0;var _=y.__H||(y.__H={__:[],__h:[]});return e>=_.__.length&&_.__.push({__V:F}),_.__[e]}function We(e,t,_){var n=Ae(K++,2);if(n.t=e,!n.__c&&(n.__=[_?_(t):qe(void 0,t),function(r){var l=n.__N?n.__N[0]:n.__[0],u=n.t(l,r);l!==u&&(n.__N=[u,n.__[1]],n.__c.setState({}))}],n.__c=y,!y.u)){y.u=!0;var i=y.shouldComponentUpdate;y.shouldComponentUpdate=function(r,l,u){if(!n.__c.__H)return!0;var f=n.__c.__H.__.filter(function(o){return o.__c});if(f.every(function(o){return!o.__N}))return!i||i.call(this,r,l,u);var a=!1;return f.forEach(function(o){if(o.__N){var h=o.__[0];o.__=o.__N,o.__N=void 0,h!==o.__[0]&&(a=!0)}}),!(!a&&n.__c.props===r)&&(!i||i.call(this,r,l,u))}}return n.__N||n.__}function Be(e,t){var _=Ae(K++,3);!c.__s&&je(_.__H,t)&&(_.__=e,_.i=t,y.__H.__h.push(_))}function ze(){for(var e;e=xe.shift();)if(e.__P&&e.__H)try{e.__H.__h.forEach(M),e.__H.__h.forEach(q),e.__H.__h=[]}catch(t){e.__H.__h=[],c.__e(t,e.__v)}}c.__b=function(e){y=null,ne&&ne(e)},c.__r=function(e){re&&re(e),K=0;var t=(y=e.__c).__H;t&&(z===y?(t.__h=[],y.__h=[],t.__.forEach(function(_){_.__N&&(_.__=_.__N),_.__V=F,_.__N=_.i=void 0})):(t.__h.forEach(M),t.__h.forEach(q),t.__h=[])),z=y},c.diffed=function(e){oe&&oe(e);var t=e.__c;t&&t.__H&&(t.__H.__h.length&&(xe.push(t)!==1&&te===c.requestAnimationFrame||((te=c.requestAnimationFrame)||Ie)(ze)),t.__H.__.forEach(function(_){_.i&&(_.__H=_.i),_.__V!==F&&(_.__=_.__V),_.i=void 0,_.__V=F})),z=y=null},c.__c=function(e,t){t.some(function(_){try{_.__h.forEach(M),_.__h=_.__h.filter(function(n){return!n.__||q(n)})}catch(n){t.some(function(i){i.__h&&(i.__h=[])}),t=[],c.__e(n,_.__v)}}),ie&&ie(e,t)},c.unmount=function(e){le&&le(e);var t,_=e.__c;_&&_.__H&&(_.__H.__.forEach(function(n){try{M(n)}catch(i){t=i}}),_.__H=void 0,t&&c.__e(t,_.__v))};var ce=typeof requestAnimationFrame=="function";function Ie(e){var t,_=function(){clearTimeout(n),ce&&cancelAnimationFrame(t),setTimeout(e)},n=setTimeout(_,100);ce&&(t=requestAnimationFrame(_))}function M(e){var t=y,_=e.__c;typeof _=="function"&&(e.__c=void 0,_()),y=t}function q(e){var t=y;e.__c=e.__(),y=t}function je(e,t){return!e||e.length!==t.length||t.some(function(_,n){return _!==e[n]})}function qe(e,t){return typeof t=="function"?t(e):t}function Ge(e,t){for(var _ in t)e[_]=t[_];return e}function ue(e,t){for(var _ in e)if(_!=="__source"&&!(_ in t))return!0;for(var n in t)if(n!=="__source"&&e[n]!==t[n])return!0;return!1}function se(e){this.props=e}(se.prototype=new k).isPureReactComponent=!0,se.prototype.shouldComponentUpdate=function(e,t){return ue(this.props,e)||ue(this.state,t)};var fe=c.__b;c.__b=function(e){e.type&&e.type.__f&&e.ref&&(e.props.ref=e.ref,e.ref=null),fe&&fe(e)};var Ke=c.__e;c.__e=function(e,t,_,n){if(e.then){for(var i,r=t;r=r.__;)if((i=r.__c)&&i.__c)return t.__e==null&&(t.__e=_.__e,t.__k=_.__k),i.__c(e,t)}Ke(e,t,_,n)};var ae=c.unmount;function Ue(e,t,_){return e&&(e.__c&&e.__c.__H&&(e.__c.__H.__.forEach(function(n){typeof n.__c=="function"&&n.__c()}),e.__c.__H=null),(e=Ge({},e)).__c!=null&&(e.__c.__P===_&&(e.__c.__P=t),e.__c=null),e.__k=e.__k&&e.__k.map(function(n){return Ue(n,t,_)})),e}function Oe(e,t,_){return e&&(e.__v=null,e.__k=e.__k&&e.__k.map(function(n){return Oe(n,t,_)}),e.__c&&e.__c.__P===t&&(e.__e&&_.insertBefore(e.__e,e.__d),e.__c.__e=!0,e.__c.__P=_)),e}function I(){this.__u=0,this.t=null,this.__b=null}function Te(e){var t=e.__.__c;return t&&t.__a&&t.__a(e)}function T(){this.u=null,this.o=null}c.unmount=function(e){var t=e.__c;t&&t.__R&&t.__R(),t&&e.__h===!0&&(e.type=null),ae&&ae(e)},(I.prototype=new k).__c=function(e,t){var _=t.__c,n=this;n.t==null&&(n.t=[]),n.t.push(_);var i=Te(n.__v),r=!1,l=function(){r||(r=!0,_.__R=null,i?i(u):u())};_.__R=l;var u=function(){if(!--n.__u){if(n.state.__a){var a=n.state.__a;n.__v.__k[0]=Oe(a,a.__c.__P,a.__c.__O)}var o;for(n.setState({__a:n.__b=null});o=n.t.pop();)o.forceUpdate()}},f=t.__h===!0;n.__u++||f||n.setState({__a:n.__b=n.__v.__k[0]}),e.then(l,l)},I.prototype.componentWillUnmount=function(){this.t=[]},I.prototype.render=function(e,t){if(this.__b){if(this.__v.__k){var _=document.createElement("div"),n=this.__v.__k[0].__c;this.__v.__k[0]=Ue(this.__b,_,n.__O=n.__P)}this.__b=null}var i=t.__a&&j(N,null,e.fallback);return i&&(i.__h=null),[j(N,null,t.__a?null:e.children),i]};var pe=function(e,t,_){if(++_[1]===_[0]&&e.o.delete(t),e.props.revealOrder&&(e.props.revealOrder[0]!=="t"||!e.o.size))for(_=e.u;_;){for(;_.length>3;)_.pop()();if(_[1]<_[0])break;e.u=_=_[2]}};(T.prototype=new k).__a=function(e){var t=this,_=Te(t.__v),n=t.o.get(e);return n[0]++,function(i){var r=function(){t.props.revealOrder?(n.push(i),pe(t,e,n)):i()};_?_(r):r()}},T.prototype.render=function(e){this.u=null,this.o=new Map;var t=W(e.children);e.revealOrder&&e.revealOrder[0]==="b"&&t.reverse();for(var _=t.length;_--;)this.o.set(t[_],this.u=[1,0,this.u]);return e.children},T.prototype.componentDidUpdate=T.prototype.componentDidMount=function(){var e=this;this.o.forEach(function(t,_){pe(e,_,t)})};var Ze=typeof Symbol<"u"&&Symbol.for&&Symbol.for("react.element")||60103,Je=/^(?:accent|alignment|arabic|baseline|cap|clip(?!PathU)|color|dominant|fill|flood|font|glyph(?!R)|horiz|image|letter|lighting|marker(?!H|W|U)|overline|paint|pointer|shape|stop|strikethrough|stroke|text(?!L)|transform|underline|unicode|units|v|vector|vert|word|writing|x(?!C))[A-Z]/,Qe=typeof document<"u",Xe=function(e){return(typeof Symbol<"u"&&typeof Symbol()=="symbol"?/fil|che|rad/i:/fil|che|ra/i).test(e)};k.prototype.isReactComponent={},["componentWillMount","componentWillReceiveProps","componentWillUpdate"].forEach(function(e){Object.defineProperty(k.prototype,e,{configurable:!0,get:function(){return this["UNSAFE_"+e]},set:function(t){Object.defineProperty(this,e,{configurable:!0,writable:!0,value:t})}})});var de=c.event;function Ye(){}function et(){return this.cancelBubble}function tt(){return this.defaultPrevented}c.event=function(e){return de&&(e=de(e)),e.persist=Ye,e.isPropagationStopped=et,e.isDefaultPrevented=tt,e.nativeEvent=e};var he={configurable:!0,get:function(){return this.class}},ve=c.vnode;c.vnode=function(e){var t=e.type,_=e.props,n=_;if(typeof t=="string"){var i=t.indexOf("-")===-1;for(var r in n={},_){var l=_[r];Qe&&r==="children"&&t==="noscript"||r==="value"&&"defaultValue"in _&&l==null||(r==="defaultValue"&&"value"in _&&_.value==null?r="value":r==="download"&&l===!0?l="":/ondoubleclick/i.test(r)?r="ondblclick":/^onchange(textarea|input)/i.test(r+t)&&!Xe(_.type)?r="oninput":/^onfocus$/i.test(r)?r="onfocusin":/^onblur$/i.test(r)?r="onfocusout":/^on(Ani|Tra|Tou|BeforeInp|Compo)/.test(r)?r=r.toLowerCase():i&&Je.test(r)?r=r.replace(/[A-Z0-9]/g,"-$&").toLowerCase():l===null&&(l=void 0),/^oninput$/i.test(r)&&(r=r.toLowerCase(),n[r]&&(r="oninputCapture")),n[r]=l)}t=="select"&&n.multiple&&Array.isArray(n.value)&&(n.value=W(_.children).forEach(function(u){u.props.selected=n.value.indexOf(u.props.value)!=-1})),t=="select"&&n.defaultValue!=null&&(n.value=W(_.children).forEach(function(u){u.props.selected=n.multiple?n.defaultValue.indexOf(u.props.value)!=-1:n.defaultValue==u.props.value})),e.props=n,_.class!=_.className&&(he.enumerable="className"in _,_.className!=null&&(n.class=_.className),Object.defineProperty(n,"className",he))}e.$$typeof=Ze,ve&&ve(e)};var ye=c.__r;c.__r=function(e){ye&&ye(e),e.__c};class _t{bind(t,_){t.updateAppState=n=>{_({type:"receivedUpdatedAppState",appState:n})}}emitter(t){return _=>{t.webkit.messageHandlers.appView.postMessage(_)}}}function nt(e,t){return()=>{const[_,n]=We(e.reducer,void 0,e.initializer);Be(()=>{e.bind(window,n)},[]);const i=e.selector(_,e.emitter(window),n);return t(i)}}class rt extends _t{initializer(){return{state:"notConnected"}}reducer(t,_){switch(_.type){case"receivedUpdatedAppState":return _.appState}}selector(t,_){return{...t,onResumeFilterClicked:()=>_("resumeFilterClicked"),onSuspendFilterClicked:()=>_("suspendFilterClicked"),onRefreshRulesClicked:()=>_("refreshRulesClicked"),onAdministrateClicked:()=>_("administrateClicked"),onViewNetworkTrafficClicked:()=>_("viewNetworkTrafficClicked"),onConnectToUserClicked:()=>_("fakeConnect")}}}const ot=new rt;var it=0;function S(e,t,_,n,i,r){var l,u,f={};for(u in t)u=="ref"?l=t[u]:f[u]=t[u];var a={type:e,props:f,key:_,ref:l,__k:null,__:null,__b:0,__e:null,__d:void 0,__c:null,__h:null,constructor:void 0,__v:--it,__source:i,__self:r};if(typeof e=="function"&&(l=e.defaultProps))for(u in l)f[u]===void 0&&(f[u]=l[u]);return c.vnode&&c.vnode(a),a}const lt=({onConnectToUserClicked:e,...t})=>t.state==="notConnected"?S("button",{className:"p-4",onClick:e,children:"Connect to a User"}):S("ul",{className:"p-4",children:[S("li",{children:["Filter state: ",t.filterState.state]}),S("li",{children:["Recording keystrokes: ",t.recordingKeystrokes?"on":"off"]}),S("li",{children:["Recording screenshots: ",t.recordingScreenshots?"on":"off"]})]}),ct=nt(ot,lt);Ve(S(ct,{}),document.getElementById("app"));
