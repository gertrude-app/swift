# 2023-08-25 -- big sur assign with copy any?

- v2.0.4
- big sur
- on mac mini (intel - 2018 i think, my office mini)
- crash was in app, not filter
- crash and symbols stored at `spaces:unsolved-crashes/fd878263-big-sur-keylogging-any`
- last usable symbolicated line ref was `MonitoringClient+Keylogging.swift:8`, which is
  where we start up keylogging (stopping first), and the next stack trace lines have to do
  with `assignWithCopy for Any?`, which seems like it has to do with the global event
  monitor, which is stored as an `Any?`

## key lines of _symbolicated_ trace below:

```
outlined assign with copy of Any? (in Gertrude) (<compiler-generated>:0)
$s3App15startKeyloggingyyYaYbFyAA16KeystrokeMonitorCXEfU_ (in Gertrude) (MonitoringClient+Keylogging.swift:8)
```

## key lines of raw crash below:

```
Thread 8 Crashed:: Dispatch queue: Swift global concurrent queue
0   libobjc.A.dylib               	0x00007fff2058d4af objc_release + 31
1   libswiftCore.dylib            	0x00007fff2cdba360 swift::metadataimpl::ValueWitnesses<swift::metadataimpl::ObjCRetainableBox>::assignWithCopy(swift::OpaqueValue*, swift::OpaqueValue*, swift::TargetMetadata<swift::InProcess> const*) + 32
2   libswiftCore.dylib            	0x00007fff2cd99102 assignWithCopy for Any? + 114
3   com.netrivet.gertrude.app     	0x0000000106337b69 0x1062ab000 + 576361
4   com.netrivet.gertrude.app     	0x00000001063353dc 0x1062ab000 + 566236
```
