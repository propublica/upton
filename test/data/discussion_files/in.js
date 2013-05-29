if(!window.console){window.console={}
}if(typeof window.console.log!=="function"){window.console.log=function(){}
}if(typeof window.console.warn!=="function"){window.console.warn=function(){}
}(function(){var R={"bootstrapInit":+new Date()},p=document,l=(/^https?:\/\/.*?linkedin.*?\/in\.js.*?$/),b=(/async=true/),D=(/^https:\/\//),J=(/\/\*((?:.|[\s])*?)\*\//m),F=(/\r/g),j=(/[\s]/g),g=(/^[\s]*(.*?)[\s]*:[\s]*(.*)[\s]*$/),x=(/_([a-z])/gi),A=(/^[\s]+|[\s]+$/g),u=(/^[a-z]{2}(_)[A-Z]{2}$/),C=(/suppress(Warnings|_warnings):true/gi),d=(/^api(Key|_key)$/gi),k="\n",G=",",n="",I="@",o="extensions",Y="on",w="onDOMReady",ab="onOnce",Z="script",L="https://www.linkedin.com/uas/js/userspace?v=0.0.2000-RC1.28014-1405",h="https://platform.linkedin.com/js/secureAnonymousFramework?v=0.0.2000-RC1.28014-1405",H="http://platform.linkedin.com/js/nonSecureAnonymousFramework?v=0.0.2000-RC1.28014-1405",B=p.getElementsByTagName("head")[0],t=p.getElementsByTagName(Z),W=[],a=[],O=["lang"],Q={},c=false,ac,m,V,r,K,E,aa;
if(window.IN&&IN.ENV&&IN.ENV.js){if(!IN.ENV.js.suppressWarnings){console.warn("duplicate in.js loaded, any parameters will be ignored")
}return
}window.IN=window.IN||{};
IN.ENV={};
IN.ENV.js={};
IN.ENV.js.extensions={};
statsQueue=IN.ENV.statsQueue=[];
statsQueue.push(R);
ac=IN.ENV.evtQueue=[];
IN.Event={on:function(){ac.push({type:Y,args:arguments})
},onDOMReady:function(){ac.push({type:w,args:arguments})
},onOnce:function(){ac.push({type:ab,args:arguments})
}};
IN.$extensions=function(af){var ai,i,ae,ah,ag=IN.ENV.js.extensions;
ai=af.split(G);
for(var ad=0,e=ai.length;
ad<e;
ad++){i=U(ai[ad],I,2);
ae=i[0].replace(A,n);
ah=i[1];
if(!ag[ae]){ag[ae]={src:(ah)?ah.replace(A,n):n,loaded:false}
}}};
function U(af,ad,e){var ag=af.split(ad);
if(!e){return ag
}if(ag.length<e){return ag
}var ae=ag.splice(0,e-1);
var i=ag.join(ad);
ae.push(i);
return ae
}function v(e,i){if(e==o){IN.$extensions(i);
return null
}if(d.test(e)){i=i.replace(j,n)
}if(i==""){return null
}return i
}function N(ae,af){af=v(ae,af);
if(af){ae=ae.replace(x,function(){return arguments[1].toUpperCase()
});
if(ae==="lang"&&!u.test(af)){try{var ad=af.replace("-","_").split("_");
ad=[ad[0].substr(0,2).toLowerCase(),ad[1].substr(0,2).toUpperCase()].join("_");
if(!u.test(ad)){throw new Error()
}else{af=ad
}}catch(ag){if(!(aa||IN.ENV.js.suppressWarnings)&&af){console.warn("'"+af+"' is not a supported language, defaulting to 'en_US'")
}af="en_US"
}}IN.ENV.js[ae]=af;
var ah=[encodeURIComponent(ae),encodeURIComponent(af)].join("=");
for(var i in O){if(O.hasOwnProperty(i)&&O[i]===ae){a.push(ah);
return
}}W.push(ah)
}}m="";
for(T=0,q=t.length;
T<q;
T++){var f=t[T];
if(!l.test(f.src)){continue
}if(b.test(f.src)){c=true
}try{m=f.innerHTML.replace(A,n)
}catch(z){try{m=f.text.replace(A,n)
}catch(y){}}}m=m.replace(J,"$1").replace(A,n).replace(F,n);
aa=C.test(m.replace(j,n));
for(var T=0,S=m.split(k),q=S.length;
T<q;
T++){var s=S[T];
if(!s||s.replace(j,n).length<=0){continue
}try{V=s.match(g);
r=V[1].replace(A,n);
K=V[2].replace(A,n)
}catch(X){if(!aa){console.warn("script tag contents must be key/value pairs separated by a colon. Source: "+X)
}continue
}N(r,K)
}N("secure",(D.test(document.location.href))?1:0);
function M(e,i){return e+((/\?/.test(e))?"&":"?")+i.join("&")
}IN.init=function P(e){var ad,ae;
e=e||{};
for(var i in e){if(e.hasOwnProperty(i)){N(i,e[i])
}}E=p.createElement(Z);
ae=(IN.ENV.js.apiKey)?M(L,W):(IN.ENV.js.secure)?h:H;
E.src=M(ae,a);
B.appendChild(E);
statsQueue.push({"userspaceRequested":+new Date()})
};
statsQueue.push({"bootstrapLoaded":+new Date()});
if(!c){IN.init()
}})();
