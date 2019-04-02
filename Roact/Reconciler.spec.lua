return function()
	local Core = require(script.Parent.Core)
	local Event = require(script.Parent.Event)
	local Change = require(script.Parent.Change)
	local createRef = require(script.Parent.createRef)
	local createElement = require(script.Parent.createElement)

	local Reconciler = require(script.Parent.Reconciler)

	it("should mount booleans as nil", function()
		local booleanReified = Reconciler.mount(false)
		expect(booleanReified).to.never.be.ok()
	end)

	it("should handle object references properly", function()
		local objectRef = createRef()
		local element = createElement("StringValue", {
			[Core.Ref] = objectRef,
		})

		local handle = Reconciler.mount(element)
		expect(objectRef.current).to.be.ok()
		Reconciler.unmount(handle)
		expect(objectRef.current).to.never.be.ok()
	end)

	it("should handle function references properly", function()
		local currentRbx

		local function ref(rbx)
			currentRbx = rbx
		end

		local element = createElement("StringValue", {
			[Core.Ref] = ref,
		})

		local handle = Reconciler.mount(element)
		expect(currentRbx).to.be.ok()
		Reconciler.unmount(handle)
		expect(currentRbx).to.never.be.ok()
	end)

	it("should handle changing function references", function()
		local aValue, bValue

		local function aRef(rbx)
			aValue = rbx
		end

		local function bRef(rbx)
			bValue = rbx
		end

		local element = createElement("StringValue", {
			[Core.Ref] = aRef,
		})

		local handle = Reconciler.mount(element, game, "Test123")
		expect(aValue).to.be.ok()
		expect(bValue).to.never.be.ok()
		handle = Reconciler.reconcile(handle, createElement("StringValue", {
			[Core.Ref] = bRef,
		}))
		expect(aValue).to.never.be.ok()
		expect(bValue).to.be.ok()
		Reconciler.unmount(handle)
		expect(bValue).to.never.be.ok()
	end)

	it("should handle changing object references", function()
		local aRef = createRef()
		local bRef = createRef()

		local element = createElement("StringValue", {
			[Core.Ref] = aRef,
		})

		local handle = Reconciler.mount(element, game, "Test123")
		expect(aRef.current).to.be.ok()
		expect(bRef.current).to.never.be.ok()
		handle = Reconciler.reconcile(handle, createElement("StringValue", {
			[Core.Ref] = bRef,
		}))
		expect(aRef.current).to.never.be.ok()
		expect(bRef.current).to.be.ok()
		Reconciler.unmount(handle)
		expect(bRef.current).to.never.be.ok()
	end)

	it("should clean up Event references properly", function()
		local sizeChangedCount = 0

		local function eventCallback(object, property)
			if property == "Size" then
				sizeChangedCount = sizeChangedCount + 1
			end
		end

		local element = createElement("Frame", {
			[Event.Changed] = eventCallback,
		})

		local container = Instance.new("Folder")
		local handle = Reconciler.mount(element, container, "Foo")
		expect(handle).to.be.ok()
		expect(sizeChangedCount).to.equal(0)
		expect(container.Foo).to.be.ok()

		container.Foo.Size = UDim2.new(0, 100, 0, 100)
		expect(sizeChangedCount).to.equal(1)

		handle = Reconciler.reconcile(handle, createElement("Frame", {
			[Event.Changed] = nil
		}))
		container.Foo.Size = UDim2.new(0, 200, 0, 200)
		expect(sizeChangedCount).to.equal(1)

		Reconciler.unmount(handle)
	end)

	it("should clean up Change references properly", function()
		local sizeChangedCount = 0

		local function changeCallback()
			sizeChangedCount = sizeChangedCount + 1
		end

		local element = createElement("Frame", {
			[Change.Size] = changeCallback,
		})

		local container = Instance.new("Folder")
		local handle = Reconciler.mount(element, container, "Foo")
		expect(handle).to.be.ok()
		expect(sizeChangedCount).to.equal(0)
		expect(container.Foo).to.be.ok()

		container.Foo.Size = UDim2.new(0, 100, 0, 100)
		expect(sizeChangedCount).to.equal(1)

		handle = Reconciler.reconcile(handle, createElement("Frame", {
			[Change.Size] = nil
		}))
		container.Foo.Size = UDim2.new(0, 200, 0, 200)
		expect(sizeChangedCount).to.equal(1)

		Reconciler.unmount(handle)
	end)
end